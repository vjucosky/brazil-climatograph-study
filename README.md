# Estudo climatográfico do Brasil

Este repositório contém os artefatos do estudo climatográfico do Brasil, que utiliza dados extraídos do [Banco de Dados Meteorológicos do INMET (BDMEP)](https://portal.inmet.gov.br/servicos/bdmep-dados-históricos).

O repositório está organizado da seguinte maneira:

* `/sql/`: scripts T-SQL para a criação das estruturas de dados.
* `/etl/`: script Python para download e carga dos dados a partir do website do BDMEP.
* `/doc/`: assets da documentação.

Todos os scripts foram desenvolvidos em Python 3.11. Para instalar as dependências, execute:

```
pip install -r requirements.txt
```

### Configuração do banco de dados

O ETL realiza a carga dos arquivos CSV extraídos do portal BDMEP em um banco de dados SQL Server. Para criar uma instância do SQL Server como desenvolvedor utilizando o Docker, execute:

```
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=my_super_secret_password" -n sql-server -p 1433:1433 -d --name sql-server mcr.microsoft.com/mssql/server:2022-latest
```

![data_structure_weather_station](/doc/data_structure_weather_station.png)

### Execução do ETL

Antes de iniciar o ETL, atualize o arquivo `/etl/.env` com as credenciais do banco de dados criado anteriormente. A execução se dá pelo arquivo `/etl/main.py`.

Os arquivos baixados são salvos temporariamente na pasta `/etl/stage/` e, conforme são carregados para o banco de dados, são movidos para a pasta `/etl/archive/`.

> [!NOTE]
> Ao executar o ETL como configurado (abrangendo os anos de 2000 a 2024), será baixado aproximadamente 6,7 GB.

### Consolidação dos resultados

Devido ao tamanho da base, optou-se por utilizar o analítico das leituras (salvas em intervalos de 1 hora) somente para as 3 estações meteorológicas mais próximas de cada "ponto de interesse" do autor. As demais estações meteorólogicas terão suas leituras agrupadas na granulometria diária para um overview do país como um todo.

Ao final da execução, teremos 3 bases de dados para consumo:

1. Pontos de interesse e estações meteorológicas próximas;
2. Analítico das leituras meteorológicas das estações próximas aos pontos de interesse; e
3. Consolidado geral de leituras.

As consultas utilizadas estão disponíveis no arquivo `/sql/DATAVIZ.sql`.
