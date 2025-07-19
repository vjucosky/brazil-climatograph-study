# Estudo climatográfico do Brasil

Este repositório contém os artefatos necessários para o estudo climatográfico do Brasil, que utiliza dados extraídos do [Banco de Dados Meteorológicos do INMET (BDMEP)](https://bdmep.inmet.gov.br/). O estudo está disponível no Tableau Public em _.

O repositório está organizado da seguinte maneira:

* `/sql/`: scripts T-SQL para a criação do banco de dados e das tabelas necessárias e querys de extração.
* `/etl/`: script Python para download e carga dos dados a partir do website do BDMEP.
* `/viz/`: pastas de trabalho do Tableau.
* `/doc/`: assets da documentação.

### Configuração do banco de dados

O ETL realiza a carga dos arquivos CSV extraídos do portal BDMEP em um banco de dados SQL Server. Para criar uma instância do SQL Server como desenvolvedor utilizando o Docker, execute:

```
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=my_super_secret_password" -n sql-server -p 1433:1433 -d --name sql-server mcr.microsoft.com/mssql/server:2022-latest
```

Após a subida da instância, execute o script disponível em `/sql/DDL.sql` para criar o banco de dados e as tabelas necessárias.

![ER](/doc/ER.png)

### Execução do ETL

O ETL foi desenvolvido em Python 3.11. Para instalar as dependências necessárias, execute:

```
pip install -r /etl/requirements.txt
```

Antes de iniciar o ETL, atualize o arquivo `/etl/.env` com as credenciais do banco de dados criado anteriormente. A execução se dá pelo arquivo `/etl/main.py`.

Os arquivos baixados são salvos temporariamente na pasta `/etl/stage/` e, conforme são carregados para o banco de dados, são movidos para a pasta `/etl/archive/`.

![Dataflow](/doc/Dataflow.png)

> [!NOTE]
> Ao executar o ETL como configurado (abrangendo os anos de 2000 a 2024), será baixado aproximadamente 6,7 GB.

### Exportação dos resultados

O Tableau Public não oferece conector ao SQL Server; assim é necessário exportar os dados em formato CSV. As consultas utilizadas estão disponíveis no arquivo `/sql/DML.sql`. Os arquivos são exportados para a pasta `/output/` mas, devido ao tamanho final (~750 MB), não foram incluídos no repositório.
