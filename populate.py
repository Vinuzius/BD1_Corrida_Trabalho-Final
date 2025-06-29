import random
from datetime import date, timedelta
import psycopg2
from psycopg2.extras import execute_values
from faker import Faker

# Configurações de conexão
DB_PARAMS = {
    'dbname': 'test_db',
    'user': 'test_user',
    'password': 'test_pass',
    'host': 'localhost',
    'port': 5432,
}

fake = Faker('pt_BR')

# Quantidades de registros
NUM_PESSOAS = 100
NUM_ATENDENTES = 20
NUM_PASSAGEIROS = 50
NUM_MOTORISTAS = 30
NUM_SEGURADORAS = 3
MAX_TELEFONES_POR_SEG = 3
MAX_VEICULOS_POR_MOTORISTA = 3
MAX_CORRIDAS_POR_PASSAGEIRO = 12
MAX_CARONISTAS_POR_CORRIDA = 3
MAX_QUESTIONAMENTOS_POR_SUPORTE = 10


def connect():
    return psycopg2.connect(**DB_PARAMS)


def set_schema(cur):
    cur.execute("SET search_path TO bd_projeto;")


def generate_pessoas(cur):
    set_schema(cur)
    pessoas = []
    for i in range(1, NUM_PESSOAS + 1):
        cpf = fake.cpf().replace('.', '').replace('-', '')
        rg = fake.rg().replace('.', '')
        endereco = fake.address().replace('\n', ', ')
        nascimento = fake.date_of_birth(minimum_age=18, maximum_age=80)
        pessoas.append((i, cpf, rg, endereco, nascimento))
    execute_values(cur,
        "INSERT INTO pessoa (id, cpf, rg, endereco, data_nascimento) VALUES %s",
        pessoas)
    return list(range(1, NUM_PESSOAS + 1))


def assign_roles(ids):
    random.shuffle(ids)
    atendentes = ids[:NUM_ATENDENTES]
    passageiros = ids[NUM_ATENDENTES:NUM_ATENDENTES+NUM_PASSAGEIROS]
    motoristas = ids[NUM_ATENDENTES+NUM_PASSAGEIROS:NUM_ATENDENTES+NUM_PASSAGEIROS+NUM_MOTORISTAS]
    return atendentes, passageiros, motoristas


def generate_atendentes(cur, atendentes):
    set_schema(cur)
    data = [(i, fake.job()) for i in atendentes]
    execute_values(cur,
        "INSERT INTO atendente (id, formacao_escolar) VALUES %s",
        data)


def generate_passageiros(cur, passageiros):
    set_schema(cur)
    data = []
    for i in passageiros:
        num = fake.credit_card_number(card_type=None)
        num = ''.join(filter(str.isdigit, num))[:16]
        data.append((i, num))
    execute_values(cur,
        "INSERT INTO passageiro (id, numero_credito) VALUES %s",
        data)


def generate_motoristas(cur, motoristas):
    set_schema(cur)
    data = []
    for i in motoristas:
        cc = fake.bban()[:20]
        cnh = fake.bothify(text='###########')
        data.append((i, cc, cnh))
    execute_values(cur,
        "INSERT INTO motorista (id, conta_corrente, cnh) VALUES %s",
        data)


def generate_seguradoras(cur):
    set_schema(cur)
    segs = []
    for i in range(1, NUM_SEGURADORAS + 1):
        cnpj = fake.cnpj().replace('.', '').replace('/', '').replace('-', '')
        nome = fake.company()
        end = fake.address().replace('\n', ', ')
        segs.append((i, cnpj, nome, end))
    execute_values(cur,
        "INSERT INTO seguradora (id, cnpj, nome, endereco) VALUES %s",
        segs)
    return list(range(1, NUM_SEGURADORAS + 1))


def generate_telefones(cur, seg_ids):
    set_schema(cur)
    data = []
    for sid in seg_ids:
        n_tels = random.randint(1, MAX_TELEFONES_POR_SEG)
        nums = set()
        for _ in range(n_tels):
            ddd = "021"
            num = fake.msisdn()[3:12]
            if (ddd, num) in nums:
                continue
            nums.add((ddd, num))
            data.append((sid, ddd, num))
    execute_values(cur,
        "INSERT INTO telefone_seguradora (id, ddd, numero) VALUES %s",
        data)


def generate_veiculos(cur, motoristas):
    set_schema(cur)
    veiculos = []
    vid = 1
    for mid in motoristas:
        n = random.randint(1, MAX_VEICULOS_POR_MOTORISTA)
        for _ in range(n):
            renavam = fake.bothify(text='###########')
            marca = fake.company()
            preco = round(random.uniform(20000, 200000), 2)
            tipo = random.choice(['ECONÔMICO', 'SUV', 'LUXO', 'RURAL'])
            modelo = fake.word().title()
            ano = random.randint(2000, 2025)
            start = date(ano, 1, 1)
            end = date.today()
            data_compra = fake.date_between(start_date=start, end_date=end)
            veiculos.append((vid, renavam, marca, preco, tipo, modelo, ano, data_compra, mid))
            vid += 1
    execute_values(cur,
        "INSERT INTO veiculo (id, renavam, marca, preco, tipo, modelo, ano, data_compra, id_motorista) VALUES %s",
        veiculos)
    return list(range(1, vid))


def generate_seguros(cur, seg_ids, veic_ids):
    set_schema(cur)
    data = []
    for vid in veic_ids:
        sid = random.choice(seg_ids)
        apolice = fake.bothify(text='APOLICE-#####')
        valor = round(random.uniform(500, 10000), 2)
        data.append((sid, apolice, vid, valor))
    execute_values(cur,
        "INSERT INTO seguro (id_seguradora, nro_apolice, id_veiculo, valor) VALUES %s",
        data)


def generate_corridas(cur, passageiros):
    set_schema(cur)
    corridas = []
    seq = 1
    for pid in passageiros:
        n = random.randint(1, MAX_CORRIDAS_POR_PASSAGEIRO)
        for _ in range(n):
            dest = fake.address().replace('\n', ', ')
            inicio = fake.date_time_between(start_date='-1y', end_date='now')
            fim = inicio + timedelta(minutes=random.randint(5, 120))
            valor = round(random.uniform(10, 500), 2)
            corridas.append((seq, pid, dest, inicio, fim, valor))
            seq += 1
    execute_values(cur,
        "INSERT INTO corrida (nro_sequencial, id_passageiro, endereco_destino, dt_hora_inicio, dt_hora_fim, valortotal) VALUES %s",
        corridas)
    return [(c[0], c[1]) for c in corridas]


def generate_solicitacoes(cur, corridas, motoristas):
    set_schema(cur)
    data = []
    for seq, pid in corridas:
        mid = random.choice(motoristas)
        valor = round(random.uniform(10, 500), 2)
        data.append((seq, pid, mid, valor))
    execute_values(cur,
        "INSERT INTO solicitacao (nro_sequencial, id_passageiro, id_motorista, valor_principal) VALUES %s",
        data)


def generate_caronistas(cur, corridas, passageiros):
    set_schema(cur)
    data = []
    for seq, pid in corridas:
        n = random.randint(0, MAX_CARONISTAS_POR_CORRIDA)
        if n == 0:
            continue
        caronistas = random.sample(passageiros, min(n, len(passageiros)))
        for car in caronistas:
            valor = round(random.uniform(5, 100), 2)
            data.append((seq, pid, car, valor))
    execute_values(cur,
        "INSERT INTO caronista (nro_sequencial, id_passageiro, id_caronista, valor_carona) VALUES %s",
        data)


def generate_suporte_e_questionamentos(cur, corridas, atendentes):
    set_schema(cur)
    sup_data = []
    quest_data = []
    for seq, pid in corridas:
        at = random.choice([None] + atendentes)
        sup_data.append((seq, pid, at))
        if at is not None:
            qn = random.randint(0, MAX_QUESTIONAMENTOS_POR_SUPORTE)
            for j in range(1, qn + 1):
                pergunta = fake.sentence()
                resposta = fake.sentence()
                quest_data.append((seq, pid, j, pergunta, resposta))
    execute_values(cur,
        "INSERT INTO suporte_corrida (nro_sequencial, id_passageiro, id_atendente) VALUES %s",
        sup_data)
    if quest_data:
        execute_values(cur,
            "INSERT INTO questionamento (nro_sequencial_corrida, id_passageiro, nro_sequencial_questionamento, pergunta, resposta) VALUES %s",
            quest_data)


def main():
    conn = connect()
    cur = conn.cursor()
    try:
        ids = generate_pessoas(cur)
        atendentes, passageiros, motoristas = assign_roles(ids)
        generate_atendentes(cur, atendentes)
        generate_passageiros(cur, passageiros)
        generate_motoristas(cur, motoristas)
        seg_ids = generate_seguradoras(cur)
        generate_telefones(cur, seg_ids)
        veic_ids = generate_veiculos(cur, motoristas)
        generate_seguros(cur, seg_ids, veic_ids)
        corridas = generate_corridas(cur, passageiros)
        generate_solicitacoes(cur, corridas, motoristas)
        generate_caronistas(cur, corridas, passageiros)
        generate_suporte_e_questionamentos(cur, corridas, atendentes)
        conn.commit()
        print("Dados inseridos com sucesso!")
    except Exception as e:
        conn.rollback()
        print("Erro ao popular o banco:", e)
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    main()
