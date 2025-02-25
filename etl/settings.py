from pathlib import Path
from os import getenv


DATABASE_SETTINGS = {
    'url': f'mssql+pyodbc://{getenv("DATABASE_USERNAME")}:{getenv("DATABASE_PASSWORD")}@localhost:1433/STUDY?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=Yes',
    'fast_executemany': True
}

BDMET_ARCHIVE_BASE_URL = 'https://portal.inmet.gov.br/uploads/dadoshistoricos/{year}.zip'

STAGE_FOLDER = Path('./stage/')

ARCHIVE_FOLDER = Path('./archive/')
