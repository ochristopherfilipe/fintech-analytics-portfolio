-- ====================================================================================
-- PROJETO FINTECH ANALYTICS PORTFOLIO
-- Arquivo: 03_consultas_analiticas.sql
-- Descrição: Scripts avançados contendo resolução de Regras de Negócios 
-- ====================================================================================

-- ------------------------------------------------------------------------------------
-- QUERY 1: Alerta de Prevenção à Fraude (Lavagem de Dinheiro)
-- Objetivo: Identificar usuários que fizeram 3 ou mais transações do tipo PIX ou TED
-- num intervalo suspeito de menos de 10 minutos entre a primeira e a última ação.
-- Utiliza: Common Table Expressions (CTE) e Window Functions (LAG)
-- ------------------------------------------------------------------------------------
WITH TransacoesLag AS (
    SELECT 
        transacao_id,
        conta_origem_id,
        valor,
        data_hora,
        -- Pega a data/hora de 2 transações atrás da MESMA conta origem
        LAG(data_hora, 2) OVER (
            PARTITION BY conta_origem_id 
            ORDER BY data_hora
        ) AS data_hora_duas_tr_atras
    FROM transacoes
    WHERE tipo_transacao IN ('PIX', 'TED') 
      AND status = 'Concluida'
)
SELECT 
    tl.conta_origem_id,
    c.nome,
    tl.data_hora_duas_tr_atras AS inicio_onda_fraude,
    tl.data_hora AS fim_onda_fraude,
    ROUND(
        EXTRACT(EPOCH FROM (tl.data_hora - tl.data_hora_duas_tr_atras)) / 60, 2
    ) AS intervalo_minutos
FROM TransacoesLag tl
JOIN contas cont ON tl.conta_origem_id = cont.conta_id
JOIN clientes c ON cont.cliente_id = c.cliente_id
WHERE tl.data_hora_duas_tr_atras IS NOT NULL
  -- Comparações de timestamp (menos de 10 min)
  AND EXTRACT(EPOCH FROM (tl.data_hora - tl.data_hora_duas_tr_atras)) / 60 <= 10;


-- ------------------------------------------------------------------------------------
-- QUERY 2: Saldo Cumulativo (Running Total) de Extrato Bancário
-- Objetivo: Mostrar a evolução financeira de saldos dia a dia. Para cada conta, 
-- lista o crédito e débito diário e também o total cumulativo acumulado até aquela data.
-- Utiliza: Agregações Condicionais (SUM CASE) associadas à WINDOW FUNCTION (SUM() OVER).
-- ------------------------------------------------------------------------------------
WITH MovimentacaoDiaria AS (
    SELECT 
        c.conta_id,
        DATE(t.data_hora) as data_movimentacao,
        -- Se a conta for o destino, é recebimento (+). Se for origem, gastou (-).
        SUM(CASE 
            WHEN t.conta_destino_id = c.conta_id THEN t.valor 
            ELSE -t.valor 
        END) AS saldo_do_dia
    FROM contas c
    JOIN transacoes t 
      ON c.conta_id = t.conta_origem_id OR c.conta_id = t.conta_destino_id
    WHERE t.status = 'Concluida'
    GROUP BY 
        c.conta_id, DATE(t.data_hora)
)
SELECT 
    md.conta_id,
    cl.nome,
    md.data_movimentacao,
    md.saldo_do_dia,
    -- Saldo Cumulativo soma todas os saldos do dia anteriores e até aquela data fixa
    SUM(md.saldo_do_dia) OVER (
        PARTITION BY md.conta_id 
        ORDER BY md.data_movimentacao
    ) AS saldo_cumulativo_historico
FROM MovimentacaoDiaria md
JOIN contas c ON md.conta_id = c.conta_id
JOIN clientes cl ON c.cliente_id = cl.cliente_id
ORDER BY md.conta_id, md.data_movimentacao;


-- ------------------------------------------------------------------------------------
-- QUERY 3: Engenharia de Retenção (Churn Analytics)
-- Objetivo: Quais clientes não efetuaram NENHUMA transação (origem) nos últimos 30 dias.
-- Essa query pode ser injetada rotineiramente para alimentar o CRM/Marketing.
-- Utiliza: Agregações (MAX), Lógica de Intervalo Temporal.
-- ------------------------------------------------------------------------------------
SELECT 
    cl.cliente_id,
    cl.nome,
    cont.conta_id,
    MAX(t.data_hora) as data_ultima_transacao,
    CURRENT_DATE - DATE(MAX(t.data_hora)) AS dias_inativo
FROM clientes cl
JOIN contas cont ON cl.cliente_id = cont.cliente_id
LEFT JOIN transacoes t ON cont.conta_id = t.conta_origem_id
GROUP BY 
    cl.cliente_id, cl.nome, cont.conta_id
HAVING MAX(t.data_hora) < (CURRENT_TIMESTAMP - INTERVAL '30 days')
   OR MAX(t.data_hora) IS NULL 
ORDER BY dias_inativo DESC;
