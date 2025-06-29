# BD1_Trabalho
Trabalho em Grupo feito para a matéria de Príncipios de Banco de Dados em 2025.1

Se trata de um sistema sobre viagens intermunicipais.
Comporta múltiplos passageiros por corrida, um motorista e atendente. 
Também é possivel cadastrar uma seguradora para o veículo do motorista

- Modelo Conceitual
- Modelo Lógico
- Normalização
- DDL 
- Povoamento de Tabelas
![Modelo Conceitual](https://github.com/Vinuzius/BD1_Corrida_Trabalho-Final/blob/main/Modelo%20Conceitual.png)
![Modelo Lógico](https://github.com/Vinuzius/BD1_Corrida_Trabalho-Final/blob/main/diagrama_do_modelo.jpeg)
## Atividade Avaliativa

Este projeto é uma atividade avaliativa da disciplina de Princípios de Banco de Dados do curso de Sistemas de Informação da Universidade Federal Fluminense (UFF).

## Como Criar e Popular o Banco de Dados

### Usando o script SQL

1.  **Criar as tabelas:**
    Execute o script `bd_projeto_DDL.sql` para criar o esquema e todas as tabelas do banco de dados. Você pode usar um cliente de banco de dados como o DBeaver ou o psql.

2.  **Popular o banco de dados:**
    Execute o script `bd_projeto_povoamento.sql` para popular as tabelas com dados de exemplo.

### Usando o script Python
Usando o script python que criamos é possível popular todas as tabelas do banco com um número indeterminado de dados para testes mais avançados.

1.  **Instale as dependências:**
    ```bash
    pip install psycopg2-binary Faker
    ```

2.  **Configure a conexão com o banco de dados:**
    Abra o arquivo `populate.py` e altere as configurações de conexão no dicionário `DB_PARAMS` para as suas credenciais do PostgreSQL.

3.  **Execute o script:**
    ```bash
    python populate.py
    ```
    O script irá gerar e inserir dados falsos no banco de dados.
