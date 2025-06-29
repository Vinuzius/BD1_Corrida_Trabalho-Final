CREATE SCHEMA IF NOT EXISTS bd_projeto;
SET search_path TO bd_projeto;


CREATE TYPE tipo_veiculo AS ENUM ('ECONOMICO', 'SUV', 'LUXO', 'RURAL');


CREATE TABLE pessoa (
 id INTEGER NOT NULL,
 cpf VARCHAR(11) NOT NULL,
 rg VARCHAR(10) NOT NULL,
 endereco VARCHAR(256) NOT NULL,
 data_nascimento DATE NOT NULL,


 PRIMARY KEY (id),
 UNIQUE (cpf)
);


CREATE TABLE atendente (
 id INTEGER NOT NULL,
 formacao_escolar VARCHAR(100),


 PRIMARY KEY (id),
 FOREIGN KEY (id) REFERENCES pessoa (id)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);


CREATE TABLE passageiro (
 id INTEGER NOT NULL,
 numero_credito VARCHAR(16),


 PRIMARY KEY (id),
 UNIQUE (numero_credito),
 FOREIGN KEY (id) REFERENCES pessoa (id)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);


CREATE TABLE motorista (
 id INTEGER NOT NULL,
 conta_corrente VARCHAR(20),
 cnh VARCHAR(11),


 PRIMARY KEY (id),
 UNIQUE (conta_corrente),
 UNIQUE (cnh),
 FOREIGN KEY (id) REFERENCES pessoa (id)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);

CREATE TABLE seguradora (
 id INTEGER NOT NULL,
 cnpj VARCHAR(14) NOT NULL,
 nome VARCHAR(128) NOT NULL,
 endereco VARCHAR(256) NOT NULL,


 PRIMARY KEY (id),
 UNIQUE (cnpj)
);


CREATE TABLE telefone_seguradora (
 id INTEGER NOT NULL,
 ddd VARCHAR(3),
 numero VARCHAR(9),


 PRIMARY KEY (id, ddd, numero),
 UNIQUE (ddd, numero),
 FOREIGN KEY (id) REFERENCES seguradora (id)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);


CREATE TABLE veiculo (
 id INTEGER NOT NULL,
 renavam VARCHAR(11) NOT NULL,
 marca VARCHAR(50) NOT NULL,
 preco DECIMAL(10, 2),
 tipo TIPO_VEICULO NOT NULL,
 modelo VARCHAR(50) NOT NULL,
 ano SMALLINT,
 data_compra DATE,
 id_motorista INTEGER NOT NULL,


 PRIMARY KEY (id),
 UNIQUE (renavam),
 FOREIGN KEY (id_motorista) REFERENCES motorista (id)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);

CREATE TABLE seguro (
 id_seguradora INTEGER NOT NULL,
 nro_apolice VARCHAR(50) NOT NULL,
 id_veiculo INTEGER NOT NULL,
 valor DECIMAL(10, 2) NOT NULL,


 PRIMARY KEY (id_veiculo),
 UNIQUE (id_seguradora, nro_apolice)
 FOREIGN KEY (id_veiculo) REFERENCES veiculo (id)
 ON DELETE CASCADE
 ON UPDATE CASCADE,
 FOREIGN KEY (id_seguradora) REFERENCES seguradora (id)
 ON DELETE SET NULL
 ON UPDATE CASCADE
);


CREATE TABLE corrida (
 nro_sequencial INTEGER NOT NULL,
 id_passageiro INTEGER NOT NULL,
 endereco_destino VARCHAR(256) NOT NULL,
 dt_hora_inicio TIMESTAMP NOT NULL,
 dt_hora_fim TIMESTAMP,
 valortotal DECIMAL(10, 2)NOT NULL,


 PRIMARY KEY (nro_sequencial, id_passageiro),
 FOREIGN KEY (id_passageiro) REFERENCES passageiro (id)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);


CREATE TABLE solicitacao (
 nro_sequencial INTEGER NOT NULL,
 id_passageiro INTEGER NOT NULL,
 id_motorista INTEGER NOT NULL,
 valor_principal DECIMAL(10, 2) NOT NULL,


 PRIMARY KEY (nro_sequencial, id_passageiro),
 FOREIGN KEY (nro_sequencial, id_passageiro) REFERENCES corrida (nro_sequencial, id_passageiro)
 ON DELETE CASCADE
 ON UPDATE CASCADE,
 FOREIGN KEY (id_motorista) REFERENCES motorista (id)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);

CREATE TABLE caronista (
 nro_sequencial INTEGER NOT NULL,
 id_passageiro INTEGER NOT NULL,
 id_caronista INTEGER NOT NULL,
 valor_carona DECIMAL(10, 2),


 PRIMARY KEY (nro_sequencial, id_passageiro, id_caronista),
 FOREIGN KEY (nro_sequencial, id_passageiro) REFERENCES corrida (nro_sequencial, id_passageiro)
 ON DELETE CASCADE
 ON UPDATE CASCADE,
 FOREIGN KEY (id_caronista) REFERENCES passageiro (id)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);


CREATE TABLE suporte_corrida (
 nro_sequencial INTEGER NOT NULL,
 id_passageiro INTEGER NOT NULL,
 id_atendente INTEGER,
 PRIMARY KEY (nro_sequencial, id_passageiro),
 FOREIGN KEY (nro_sequencial, id_passageiro) REFERENCES corrida (nro_sequencial, id_passageiro)
 ON DELETE CASCADE
 ON UPDATE CASCADE,
 FOREIGN KEY (id_atendente) REFERENCES atendente (id)
 ON DELETE SET NULL
 ON UPDATE CASCADE
);


CREATE TABLE questionamento (
 nro_sequencial_corrida INTEGER NOT NULL,
 id_passageiro INTEGER NOT NULL,
 nro_sequencial_questionamento INTEGER NOT NULL,
 pergunta TEXT,
 resposta TEXT,
 PRIMARY KEY (nro_sequencial_corrida, id_passageiro, nro_sequencial_questionamento),
 FOREIGN KEY (nro_sequencial_corrida, id_passageiro) REFERENCES suporte_corrida (nro_sequencial, id_passageiro)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);
