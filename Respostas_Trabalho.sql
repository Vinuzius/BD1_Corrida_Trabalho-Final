SET search_path TO bd_projeto;

--1. Dado uma seguradora, identificar quais são os veículos com seguros sob sua responsabilidade e listar as vigências das apólices.
----- Usei id_seguradora = 2 para teste
/*
 Leitura de seguradora com seleção de id_seguradora,
 A junção com seguradora e veiculo é feita apenas para dar mais detalhes na resposta
*/
SELECT s.nome Seguradora, seg.nro_apolice Apolice, seg.valor , seg.id_veiculo Veiculo_id,
       v.renavam veiculo_Renavam
FROM bd_projeto.seguro AS seg
    JOIN bd_projeto.seguradora AS s
      ON s.id = seg.id_seguradora
    JOIN bd_projeto.veiculo v
        ON v.id = seg.id_veiculo
WHERE seg.id_seguradora = 2;


--2. Dado um atendente, descubra se ele já usou o serviço de corridas e quando.
----- Usei id_atendente = 3 para teste
/*
 Leitura de atendente e junção com corrida, caso ele tenha feito corrida,
ele será passageiro e estará dentro de corrida
 Uso do cast apenas para melhorar a visualização da resposta
*/
SELECT c.id_passageiro as Atendente, c.endereco_destino AS endereco,
       CAST(c.dt_hora_inicio AS TIMESTAMP(0)) as data -- tirar os milissegundos
FROM atendente AS a
    JOIN corrida AS c
        ON c.id_passageiro = a.id
WHERE a.id = 3;


--3. Listar quais foram os passageiros que nunca fizeram uma corrida.
/*
 Passageiro junção a esquerda com corrida, caso id de corrida seja nulo, o passageiro nunca fez corrida
então filtrei apenas os nulos
 Ordenado por passageiro apenas para melhor visualização.
*/
SELECT p.id as passageiro_sem_corrida
FROM passageiro AS p
    LEFT JOIN bd_projeto.corrida c
        ON p.id = c.id_passageiro
WHERE c.id_passageiro ISNULL
ORDER BY passageiro_sem_corrida;

--4. Dado um passageiro, mostrar a quantidade de vezes onde ele foi o passageiro principal ou o caronista.
----- Usei id_passageiro = 58 para teste
/*
 1° query irá ler a corrida, a corrida define o passageiro principal, então é só filtrar o passageiro desejado
 2° query irá ler caronista e filtrar o passageiro desejado
 Utilizei produto cartesiano pois as 2 querys resultam uma tabela com 1 coluna e 1 entrada apenas, caso usasse junção
vai ocorrer erro caso o resultado de alguma das querys seja nula (passageiro nunca foi caronista ou principal)
 Criei uma coluna passageiro apenas para melhor visualização da resposta
*/

SELECT '58' as passageiro, foi_principal,foi_carona
FROM ( -- subquery para contar as vezes que foi principal
        SELECT count(*) foi_principal
        FROM corrida c
        WHERE c.id_passageiro = 58
    ) AS principal,
    (-- subquery para contar as vezes que foi caronista
        SELECT count(*) foi_carona
        FROM caronista car
        WHERE car.id_caronista = 58
    ) AS caronista;

--5. Dada uma corrida, listar todas as perguntas e respostas feitas ao atendente responsável.
-- corrida (nro =1, id =2)
/*
 Não percebi necessidade a junção de suporte com corrida pois, suporte já tem as chaves de corrida(nro_seq e id_passageiro)
 Realizei a junção de suporte com questionamento e selecionei apenas a corrida desejada
 */
SELECT s.id_atendente atendente ,q.pergunta, q.resposta
FROM suporte_corrida s
    JOIN questionamento q
        ON (q.id_passageiro,q.nro_sequencial_corrida) = (s.id_passageiro,s.nro_sequencial)
WHERE q.nro_sequencial_corrida =1 AND  q.id_passageiro = 2;


--6. Listar todos os passageiros e o valor percentual pago por eles em corridas com mais de um passageiro.
/*
 1° Query para achar passageiros principais com corridas que tem 2+ pessoas,
para isto é necessária a junção de corrida com solicitação, para conseguir o valor principal e total,
depois junção com caronista para filtrar apenas corrida que possua caronista
 2° Query para achar todos os caronistas
 colunas (nro_corrida,id_corrida) para poder distinguir as corridas
 coluna id_pessoa para saber qual a pessoa, visto que pode ter 2 ou mais caronistas
 coluna tipo_passageiro apenas para facilitar visualização
 ROUND para arredondar para 3 casas
*/
SELECT DISTINCT s.nro_sequencial nro_corrida,
       s.id_passageiro id_corrida,
       'principal' as tipo_passageiro,
       s.id_passageiro id_pessoa,
       ROUND( (valor_principal / valortotal * 100), 3) percentual
FROM corrida c -- preciso da junção com corrida apenas para pegar o valor total
        JOIN solicitacao s
            ON c.nro_sequencial = s.nro_sequencial AND c.id_passageiro = s.id_passageiro
        JOIN caronista c2
            ON c.nro_sequencial = c2.nro_sequencial AND c.id_passageiro = c2.id_passageiro

UNION ALL

SELECT car.nro_sequencial nro_corrida,
       car.id_passageiro id_corrida,
       'caronista' as tipo_passageiro,
       car.id_caronista id_pessoa,
       ROUND( (valor_carona / valortotal * 100), 3) percentual
FROM corrida c -- preciso da junção apenas para pegar o valor total
         JOIN caronista car
             ON c.nro_sequencial = car.nro_sequencial AND c.id_passageiro = car.id_passageiro
ORDER BY id_corrida,
         nro_corrida,
         tipo_passageiro DESC;


--7. Listar todos os passageiros e mostrar a quantidade de vezes onde ele foi o passageiro principal ou o passageiro caronista.
/*
 1° Query retorna quantas vezes cada passageiro foi principal
 2° Query retorna quantas vezes cada passageiro foi caronista
 Se faz um LEFT JOIN para poder capturar os casos nulos
 Utiliza a função COALESCE para retornar 0 caso o resultado for nulo
 */
SELECT p.id as passageiro,
       COALESCE(foi_principal,0) principal,
       COALESCE(foi_carona,0) caronista
FROM passageiro p LEFT JOIN
    (-- passageiro principal
        SELECT
          c.id_passageiro id ,COUNT(*) foi_principal
        FROM
          corrida c
        GROUP BY (c.id_passageiro)
    ) as principal ON p.id = principal.id
    LEFT JOIN
    (-- passageiro caronista
        SELECT id_caronista id,count(*) foi_carona
        FROM caronista car
        GROUP BY (car.id_caronista)
    ) as caronista ON caronista.id = p.id
ORDER BY (p.id);

--8.1. Quais motoristas realizaram corridas nos últimos 3 meses, e qual o valor total recebido por eles?
/*
 Junção de solicitação com corrida para conseguir capturar o id_Motorista e a data da corrida
 Faz uma seleção da data atual e subtrai o intervalo de 3 meses
*/
SELECT max(id_motorista) motorista, count(id_motorista) total_corridas,
       sum(c.valortotal) valor
FROM solicitacao s JOIN corrida c
    ON c.nro_sequencial = s.nro_sequencial AND c.id_passageiro = s.id_passageiro
WHERE  c.dt_hora_inicio >= (CURRENT_DATE - INTERVAL '3 months')
GROUP BY (id_motorista)
ORDER BY (total_corridas) DESC;

--8.2. Quantas perguntas foram respondidas por cada atendentes entre 10/5/2024 e 20/5/2024
/*
 Corrida junção Suporte para obter a data e o atendente
 Junção de suporte com questionamento para conseguir as respostas
 Filtro do tempo determinado, considera que o atendente sempre vai responder então se existe uma pergunta,
irá ter resposta.
 */
SELECT max(id_atendente) atendente,count(*) total_perguntas_respondidas
FROM
    corrida c JOIN suporte_corrida sc
        ON c.nro_sequencial = sc.nro_sequencial AND c.id_passageiro = sc.id_passageiro
    JOIN questionamento q
      ON sc.nro_sequencial = q.nro_sequencial_corrida AND sc.id_passageiro = q.id_passageiro
WHERE
    c.dt_hora_inicio >= '2024-05-10' AND c.dt_hora_inicio <= '2024-05-20' AND
    pergunta IS NOT NULL -- considera que toda pergunta tem uma resposta
GROUP BY sc.id_atendente
ORDER BY atendente;


--9.Repita as perguntas 6 e 7 com os resultados por passageiros e por ano durante a última década (2020-2025).

---9.1 Listar todos os passageiros e o valor percentual pago por eles em corridas com mais de um passageiro.
/*
 1° query faz a junção de corrida com solicitação para pegar valor total e principal,
seleciona por década e corrida que possui caronista, particiona por ano e por passageiro
 2° query faz a junção de corrida com caronista para pegar valor total e carona,
seleciona por década, particiona por ano e caronista
 Faz a união entre as duas tabelas
 */
SELECT s.id_passageiro pessoa, 'principal' as tipo,
       EXTRACT(YEAR FROM c.dt_hora_inicio) as ano,
       ROUND( ( sum(s.valor_principal) / sum(c.valortotal) * 100 ) ,3) percentual_ano
FROM corrida c -- preciso da junção apenas para pegar o valor total
        JOIN solicitacao s
            ON c.nro_sequencial = s.nro_sequencial AND c.id_passageiro = s.id_passageiro
WHERE (FLOOR(EXTRACT(YEAR FROM c.dt_hora_inicio) / 10) * 10) = 2020
  AND (c.nro_sequencial, c.id_passageiro) IN -- Só vai pegar corridas que existirem dentro de carona
        ( SELECT nro_sequencial, id_passageiro FROM caronista )
GROUP BY ano, s.id_passageiro

UNION

SELECT car.id_caronista pessoa, 'caronista' as tipo,
       EXTRACT(YEAR FROM c.dt_hora_inicio) as ano,
       ROUND( ( sum(valor_carona) / sum(valortotal) * 100), 3) percentual_ano

FROM corrida c -- preciso da junção apenas para pegar o valor total
         JOIN caronista car
             ON c.nro_sequencial = car.nro_sequencial AND c.id_passageiro = car.id_passageiro
WHERE (FLOOR(EXTRACT(YEAR FROM c.dt_hora_inicio) / 10) * 10) = 2020
GROUP BY ano, car.id_caronista
ORDER BY pessoa,  ano;

---9.2  Listar todos os passageiros e mostrar a quantidade de vezes onde ele foi o passageiro principal ou o passageiro caronista.
/*
 Subquery vai pegar todas as vezes que o passageiro foi principal e caronista na década de 2020s
vai unir as 2 tabelas, particionar por id e ano, depois contar por tipo
 Após contar os tipos, é feito a LEFT JOIN com passageiro para juntar por id e os passageiros que não tem corrida
são nulos, então é possível visualizar quem não tem corrida nessa década.
 */

SELECT p.id passageiro, ano,
       coalesce(principal_count,0) as principal,
       coalesce(caronista_count,0) as caronista
FROM passageiro p LEFT JOIN (
    SELECT passageiro_id,
           ano, -- vai contar por tipo
           COUNT(*) FILTER (WHERE tipo = 'principal') AS principal_count,
           COUNT(*) FILTER (WHERE tipo = 'carona')    AS caronista_count
    FROM ( -- pegar todas as corridas por ano e tipo
         SELECT c.id_passageiro passageiro_id, 'principal' tipo,
                EXTRACT(YEAR FROM dt_hora_inicio) ano
         FROM corrida c
         WHERE (FLOOR(EXTRACT(YEAR FROM c.dt_hora_inicio) / 10) * 10) = 2020
         UNION ALL
         SELECT car.id_caronista passageiro_id,
                'carona' tipo,
                EXTRACT(YEAR FROM dt_hora_inicio) ano
         FROM caronista car
                  JOIN corrida c
                       ON car.nro_sequencial = c.nro_sequencial AND car.id_passageiro = c.id_passageiro
         WHERE (FLOOR(EXTRACT(YEAR FROM c.dt_hora_inicio) / 10) * 10) = 2020
    ) AS total_corridas GROUP BY passageiro_id, ano
) as total_por_ano ON p.id = total_por_ano.passageiro_id
ORDER BY p.id;

