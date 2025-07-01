SET search_path TO bd_projeto;

--1. Dado uma seguradora, identificar quais são os veículos com seguros sob sua responsabilidade e listar as vigências das apólices.
-- Usei id = 2 para teste
SELECT s.nome Seguradora, seg.nro_apolice Apolice, seg.valor , seg.id_veiculo Veiculo_id,
       v.renavam veiculo_Renavam
FROM bd_projeto.seguradora AS s
    JOIN bd_projeto.seguro AS seg
      ON s.id = seg.id_seguradora
    JOIN bd_projeto.veiculo v
        ON v.id = seg.id_veiculo
WHERE seg.id_seguradora = 2;


--2. Dado um atendente, descubra se ele já usou o serviço de corridas e quando.
---------- tive que mudar o POVOAMENTO pois o gemini nao colocou nenhum atendente como passageiro
-- Usei id = 3 para teste
SELECT c.id_passageiro, c.endereco_destino AS endereco,
       CAST(c.dt_hora_fim AS TIMESTAMP(0)) as data -- tirar os milissegundos
FROM atendente AS a
    JOIN corrida AS c
        ON c.id_passageiro = a.id
WHERE a.id = 3;


--3. Listar quais foram os passageiros que nunca fizeram uma corrida.
SELECT p.id as passageiro
FROM passageiro AS p
    LEFT JOIN bd_projeto.corrida c
        ON p.id = c.id_passageiro
WHERE c.id_passageiro ISNULL
ORDER BY passageiro;

--4. Dado um passageiro, mostrar a quantidade de vezes onde ele foi o passageiro principal ou o caronista.
-- Usei id = 28 para teste
SELECT principal_id as passageiro, foi_principal, foi_carona
FROM ( -- subquery para contar as vezes que foi principal
        SELECT max(p.id) principal_id,count(p.id) foi_principal
        FROM passageiro p
            JOIN corrida c
             ON p.id = c.id_passageiro
        WHERE p.id = 28
    ) AS principal
        JOIN
    (-- subquery para contar as vezes que foi caronista
        SELECT max(car.id_caronista) caronista_id ,count(car.nro_sequencial) foi_carona
        FROM caronista car
        WHERE car.id_caronista = 28
    ) AS caronista
        ON caronista_id = principal_id;


--5. Dada uma corrida, listar todas as perguntas e respostas feitas ao atendente responsável.
-- corrida (nro =1, id =2)
SELECT s.id_atendente atendente ,q.pergunta, q.resposta
FROM suporte_corrida s
    JOIN questionamento q
        ON (q.id_passageiro,q.nro_sequencial_corrida) = (s.id_passageiro,s.nro_sequencial)
WHERE nro_sequencial_corrida =1 AND  q.id_passageiro = 2;


--6. Listar todos os passageiros e o valor percentual pago por eles em corridas com mais de um passageiro.
/*
 Primeiro Query para achar passageiros principais com corridas que tem 2+ pessoas
 Segundo Query para achar os caronistas
 coluna tipo_passageiro apenas para facilitar visualização
 ROUND para arredondar para 3 casas
*/
SELECT DISTINCT s.nro_sequencial nro_corrida,
       s.id_passageiro id_corrida,
       'principal' as tipo_passageiro,
       s.id_passageiro id_pessoa,
       ROUND( (valor_principal / valortotal * 100), 3) percentual
FROM corrida c -- preciso da junção apenas para pegar o valor total
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

SELECT principal_id as passageiro_id, foi_principal, foi_carona
FROM ( -- subquery para contar as vezes que foi principal
        SELECT max(c.id_passageiro) principal_id,count(c.id_passageiro) foi_principal
        FROM corrida c
        GROUP BY (c.id_passageiro)
    ) AS principal JOIN
    (-- subquery para contar as vezes que foi caronista
        SELECT max(car.id_caronista) caronista_id ,count(car.id_passageiro) foi_carona
        FROM caronista car
        GROUP BY (id_caronista)
    ) AS caronista
        ON caronista_id = principal_id
ORDER BY passageiro_id;


--8.1. Quais motoristas realizaram corridas nos últimos 3 meses, e qual o valor total recebido por eles?

SELECT max(id_motorista) motorista, count(id_motorista) total_corridas,
       cast(max(c.dt_hora_inicio) as TIMESTAMP(0) ) data,
       sum(c.valortotal) valor
FROM solicitacao s JOIN corrida c
    ON c.nro_sequencial = s.nro_sequencial AND c.id_passageiro = s.id_passageiro
WHERE  c.dt_hora_inicio >= (CURRENT_DATE - INTERVAL '3 months')
GROUP BY (id_motorista)
ORDER BY (total_corridas) DESC;


--8.2. Quantas perguntas foram respondidas por cada atendentes entre 10/5/2024 e 20/5/2024

SELECT max(id_atendente) atendente,count(*) total_perguntas_respondidas
FROM
    corrida c JOIN bd_projeto.suporte_corrida sc
        ON c.nro_sequencial = sc.nro_sequencial AND c.id_passageiro = sc.id_passageiro
    JOIN questionamento q
      ON sc.nro_sequencial = q.nro_sequencial_corrida AND sc.id_passageiro = q.id_passageiro
WHERE
    c.dt_hora_inicio >= '2024-05-10' AND c.dt_hora_inicio <= '2024-05-20' AND
    pergunta IS NOT NULL -- considera que toda pergunta tem uma resposta
GROUP BY sc.id_atendente
ORDER BY atendente;


--9.Repita as perguntas 6 e 7 com os resultados por passageiros e por ano durante a última década (2020-2025).
------ aqui eu preciso separar passageiro e ano?
---9.1
    SELECT s.nro_sequencial nro_corrida,
           s.id_passageiro id_corrida,
           'principal' as tipo_passageiro,
           s.id_passageiro id_pessoa,
           ROUND( (valor_principal / valortotal * 100), 3) percentual,
           EXTRACT(YEAR FROM c.dt_hora_inicio) as ano
    FROM corrida c -- preciso da junção apenas para pegar o valor total
            JOIN solicitacao s
                ON c.nro_sequencial = s.nro_sequencial AND c.id_passageiro = s.id_passageiro
    WHERE
        (FLOOR(EXTRACT(YEAR FROM c.dt_hora_inicio) / 10) * 10) = 2020 AND
        EXISTS ( --corrida com pelo menos um caronista
            SELECT 1
            FROM bd_projeto.caronista c2_exists
            WHERE c2_exists.nro_sequencial = c.nro_sequencial
              AND c2_exists.id_passageiro = c.id_passageiro
        )
    UNION ALL
    SELECT car.nro_sequencial nro_corrida,
           car.id_passageiro id_corrida,
           'caronista' as tipo_passageiro,
           car.id_caronista id_pessoa,
           ROUND( (valor_carona / valortotal * 100), 3) percentual,
           EXTRACT(YEAR FROM c.dt_hora_inicio) as ano
    FROM corrida c -- preciso da junção apenas para pegar o valor total
             JOIN caronista car
                 ON c.nro_sequencial = car.nro_sequencial AND c.id_passageiro = car.id_passageiro
    WHERE (FLOOR(EXTRACT(YEAR FROM c.dt_hora_inicio) / 10) * 10) = 2020 -- qual melhor forma de filtrar decada
    ORDER BY id_corrida, nro_corrida,
             tipo_passageiro DESC ;
---9.2

SELECT max(c.id_passageiro) passageiro,count(c.id_passageiro) vezes,
       'principal' as tipo_passageiro, EXTRACT(YEAR FROM c.dt_hora_inicio) ano
FROM corrida c
WHERE c.dt_hora_inicio >= '2020-01-01' AND c.dt_hora_inicio <= '2029-12-31'
GROUP BY (c.id_passageiro, EXTRACT(YEAR FROM c.dt_hora_inicio))
UNION ALL
SELECT max(car.id_caronista) passageiro ,count(car.id_passageiro) vezes,
       'caronista' as tipo_passageiro, EXTRACT(YEAR FROM c.dt_hora_inicio) ano
FROM caronista car JOIN corrida c
    ON car.nro_sequencial = c.nro_sequencial AND car.id_passageiro = c.id_passageiro
WHERE c.dt_hora_inicio >= '2020-01-01' AND c.dt_hora_inicio <= '2029-12-31'
GROUP BY (id_caronista, EXTRACT(YEAR FROM c.dt_hora_inicio) )

ORDER BY passageiro,ano
