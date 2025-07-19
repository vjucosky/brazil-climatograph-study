/*
   Esse arquivo contém querys para uma análise exploratória do BDMEP e consultas para exportação de dados para uso
   no Tableau.
   
   Devido ao tamanho da base, optou-se por utilizar o analítico das leituras (salvas em intervalos de 1 hora) somente
   para as 3 estações meteorológicas mais próximas de cada "ponto de interesse" do autor. As demais estações
   meteorólogicas terão suas leituras agrupadas em granulometria diária para um overview do país como um todo.

   Ao final da execução, teremos 3 bases de dados para consumo no Tableau:
   - Pontos de interesse e estações meteorológicas próximas;
   - Analítico das leituras meteorológicas das estações próximas aos pontos de interesse; e
   - Consolidado geral de leituras.

   O relacionamento entre os pontos de interesse e as leituras será realizado no Tableau através do ID da estação.
*/

-- Pontos de interesse do autor:
CREATE TABLE #INTEREST_POINT (
	ID bigint IDENTITY(1, 1) NOT NULL,
	[NAME] varchar(255) NOT NULL,
	LATITUDE decimal(8, 6) NOT NULL,
	LONGITUDE decimal(9, 6) NOT NULL,
	COORDINATE AS geography::Point(LATITUDE, LONGITUDE, 4326),
	CREATED_AT datetime NOT NULL CONSTRAINT DF__INTEREST_POINT__CREATED_AT DEFAULT GETDATE(),

	CONSTRAINT PK__INTEREST_POINT__ID PRIMARY KEY (ID)
)

INSERT INTO #INTEREST_POINT ([NAME], LATITUDE, LONGITUDE) VALUES
	('MASP', -23.561670, -46.656015),
	('Estágio', -23.552674, -46.658228),
	('Fundação', -23.548108, -46.632963),
	('Memórias de outra vida', -23.993453, -46.201984),
	('Oásis', -22.412453, -47.523687),
	('Primeiro amor', -25.581080, -49.396755)
	
-- Encontrando as 3 estações meteorológicas mais próximas de cada ponto de interesse e suas distâncias:
SELECT *
INTO #INTEREST_POINT_WEATHER_STATION
FROM (
	SELECT
		[IP].ID AS INTEREST_POINT_ID,
		WS.ID AS WEATHER_STATION_ID,
		ROW_NUMBER() OVER (
			PARTITION BY [IP].ID
			ORDER BY [IP].COORDINATE.STDistance(WS.COORDINATE)
		) AS [CLASSIFICATION],
		[IP].COORDINATE.STDistance(WS.COORDINATE) AS DISTANCE
	FROM #INTEREST_POINT AS [IP]
	CROSS JOIN WEATHER_STATION AS WS
) AS T
WHERE [CLASSIFICATION] <= 3
ORDER BY
	INTEREST_POINT_ID,
	[CLASSIFICATION]

-- Familiarizando-se com os resultados a nível de estação meteorológica:
SELECT
	IPWS.INTEREST_POINT_ID,
	[IP].[NAME] AS INTEREST_POINT_NAME,
	IPWS.WEATHER_STATION_ID,
	IPWS.[CLASSIFICATION],
	IPWS.DISTANCE,
	WS.CODE,
	WS.[NAME],
	WS.[STATE],
	WS.ALTITUDE,
	WS.FOUNDED_AT
FROM #INTEREST_POINT AS [IP]
INNER JOIN #INTEREST_POINT_WEATHER_STATION AS IPWS
	ON [IP].ID = IPWS.INTEREST_POINT_ID
INNER JOIN WEATHER_STATION AS WS
	ON IPWS.WEATHER_STATION_ID = WS.ID

-- Exportação 1 - pontos de interesse e estações meteorológicas próximas:
SELECT
	IPWS.INTEREST_POINT_ID AS [ID do ponto de interesse],
	[IP].[NAME] AS [Ponto de interesse],
	IPWS.WEATHER_STATION_ID AS [ID da estação],
	IPWS.[CLASSIFICATION] AS Classificação,
	IPWS.DISTANCE AS Distância,
	WS.[NAME] AS Estação,
	WS.[STATE] AS Estado,
	CAST(WS.LATITUDE AS float) AS [Latitude da estação],
	CAST(WS.LONGITUDE AS float) AS [Longitude da estação],
	FORMAT(WS.FOUNDED_AT, 'dd/MM/yyyy') AS [Data de fundação]
FROM #INTEREST_POINT AS [IP]
INNER JOIN #INTEREST_POINT_WEATHER_STATION AS IPWS
	ON [IP].ID = IPWS.INTEREST_POINT_ID
INNER JOIN WEATHER_STATION AS WS
	ON IPWS.WEATHER_STATION_ID = WS.ID

-- Exportação 2 - analítico das leituras meteorológicas das estações próximas aos pontos de interesse:
SELECT
	STATION_ID AS [ID da estação],
	PRECIPITATION AS Precipitação,
	PRESSURE AS Pressão,
	RADIATION AS Radiação,
	DRY_AIR_TEMPERATURE AS [Temperatura - bulbo seco],
	WET_AIR_TEMPERATURE AS [Temperatura - ponto de orvalho],
	RELATIVE_HUMIDITY AS [Umidade relativa],
	WIND_DIRECTION AS [Direção do vento],
	WIND_GUST AS [Rajada do vento],
	WIND_SPEED AS [Velocidade do vento],
	FORMAT([TIMESTAMP], 'dd/MM/yyyy HH:mm:ss') AS Horário
FROM WEATHER_STATION_READING
WHERE STATION_ID IN (
	SELECT WEATHER_STATION_ID
	FROM #INTEREST_POINT_WEATHER_STATION
)
