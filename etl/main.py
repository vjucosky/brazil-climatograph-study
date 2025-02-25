import requests


from settings import DATABASE_SETTINGS, BDMET_ARCHIVE_BASE_URL, STAGE_FOLDER, ARCHIVE_FOLDER
from sqlalchemy import Engine, create_engine, text
from datetime import datetime
from zipfile import ZipFile
from pandas import read_csv
from shutil import rmtree
from io import BytesIO


bdmet_line_parser = lambda x: x.split(':;')[1].strip()

def bdmet_float_parser(value: str):
    try:
        return float(value.replace(',', '.'))
    except ValueError:
        return None

def bdmet_date_parser(value: str):
    for pattern in ['%Y-%m-%d', '%d/%m/%y']:
        try:
            return datetime.strptime(value, pattern).date()
        except ValueError:
            pass

def load_historical_data(engine: Engine, year: int):
    print(f'Downloading historical data for year {year}')

    request = requests.get(BDMET_ARCHIVE_BASE_URL.format(year=year))

    with ZipFile(BytesIO(request.content)) as archive:
       archive.extractall(STAGE_FOLDER)

    for file in STAGE_FOLDER.rglob('*.csv'):
        print(f'Loading file {file.name}')

        data = file.open(encoding='ISO-8859-1')

        region = bdmet_line_parser(data.readline())
        state = bdmet_line_parser(data.readline())
        name = bdmet_line_parser(data.readline())
        code = bdmet_line_parser(data.readline())
        latitude = bdmet_float_parser(bdmet_line_parser(data.readline()))
        longitude = bdmet_float_parser(bdmet_line_parser(data.readline()))
        altitude = bdmet_float_parser(bdmet_line_parser(data.readline()))
        founded_at = bdmet_date_parser(bdmet_line_parser(data.readline()))

        data.seek(0)

        dataframe = read_csv(data, delimiter=';', header=8, index_col=False, usecols=[0, 1, 2, 3, 6, 7, 8, 15, 16, 17, 18], na_values=['-9999'], decimal=',', parse_dates={'timestamp': [0, 1]})

        dataframe.rename({
            'PRECIPITAÇÃO TOTAL, HORÁRIO (mm)': 'PRECIPITATION',
            'PRESSAO ATMOSFERICA AO NIVEL DA ESTACAO, HORARIA (mB)': 'PRESSURE',
            'RADIACAO GLOBAL (KJ/m²)': 'RADIATION',
            'RADIACAO GLOBAL (Kj/m²)': 'RADIATION', # Only for 2020 onwards
            'TEMPERATURA DO AR - BULBO SECO, HORARIA (°C)': 'DRY_AIR_TEMPERATURE',
            'TEMPERATURA DO PONTO DE ORVALHO (°C)': 'WET_AIR_TEMPERATURE',
            'UMIDADE RELATIVA DO AR, HORARIA (%)': 'RELATIVE_HUMIDITY',
            'VENTO, DIREÇÃO HORARIA (gr) (° (gr))': 'WIND_DIRECTION',
            'VENTO, RAJADA MAXIMA (m/s)': 'WIND_GUST',
            'VENTO, VELOCIDADE HORARIA (m/s)': 'WIND_SPEED'
        }, inplace=True, axis=1)

        with engine.connect() as connection:
            station_id = connection.execute(text('''
                SET NOCOUNT ON

                IF NOT EXISTS(
                    SELECT 1
                    FROM WEATHER_STATION
                    WHERE [CODE] = :code
                )
                BEGIN
                    INSERT INTO WEATHER_STATION (
                        [CODE],
                        [NAME],
                        [STATE],
                        ALTITUDE,
                        LATITUDE,
                        LONGITUDE,
                        FOUNDED_AT
                    )
                    VALUES (
                        :code,
                        :name,
                        :state,
                        :altitude,
                        :latitude,
                        :longitude,
                        :founded_at
                    )
                END

                SELECT ID
                FROM WEATHER_STATION
                WHERE [CODE] = :code
            '''), {
                'code': code,
                'name': name,
                'state': state,
                'altitude': altitude,
                'latitude': latitude,
                'longitude': longitude,
                'founded_at': founded_at
            }).one()[0]

            dataframe['STATION_ID'] = station_id

            dataframe.to_sql('WEATHER_STATION_READING', connection, if_exists='append', index=False, chunksize=10000)

            connection.commit()

        data.close()

        file.rename(ARCHIVE_FOLDER / file.name)

    for folder in STAGE_FOLDER.iterdir():
        rmtree(folder)


if __name__ == '__main__':
    engine = create_engine(**DATABASE_SETTINGS)

    for year in range(2000, 2025):
        load_historical_data(engine, year)
