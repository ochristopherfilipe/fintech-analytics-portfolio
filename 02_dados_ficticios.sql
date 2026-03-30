-- ====================================================================================
-- PROJETO FINTECH ANALYTICS PORTFOLIO
-- Arquivo: 02_dados_ficticios.sql
-- Descrição: DML para popular o banco de dados e simular cenários de negócio
-- ====================================================================================

TRUNCATE TABLE transacoes, contas, clientes RESTART IDENTITY CASCADE;

-- 1. Inserindo Clientes
INSERT INTO clientes (nome, cpf, tipo_cliente, data_cadastro, status) VALUES
('Ana Silva', '111.111.111-11', 'PF', '2023-01-15', 'Ativo'),
('Carlos Souza', '222.222.222-22', 'PF', '2023-02-20', 'Ativo'),
('Empresa XYZ', '33.333.333/0001', 'PJ', '2022-11-05', 'Ativo'),
('Mariana Costa', '444.444.444-44', 'PF', '2023-08-10', 'Ativo'),
('João Peixoto', '555.555.555-55', 'PF', '2022-01-10', 'Inativo'); -- Cliente Churn / Inativo

-- 2. Inserindo Contas Associadas
INSERT INTO contas (cliente_id, saldo, limite_credito, tipo_conta, data_abertura) VALUES
(1, 5000.00, 1000.00, 'Corrente', '2023-01-15'),  -- Conta 1 (Ana)
(2, 12000.50, 5000.00, 'Corrente', '2023-02-21'), -- Conta 2 (Carlos)
(3, 105000.00, 20000.00, 'Corrente', '2022-11-05'), -- Conta 3 (Empresa XYZ)
(1, 15000.00, 0.00, 'Investimento', '2023-06-10'), -- Conta 4 (Ana Inv)
(4, 300.00, 500.00, 'Corrente', '2023-08-10'),     -- Conta 5 (Mariana)
(5, 50.00, 0.00, 'Corrente', '2022-01-12');        -- Conta 6 (João - Churn)

-- 3. Inserindo Transações

-- -> Cenário A: Comportamento Normal Rotineiro (Auxilia no Saldo Cumulativo)
INSERT INTO transacoes (conta_origem_id, conta_destino_id, valor, tipo_transacao, status, data_hora) VALUES
(1, 3,  500.00, 'PIX', 'Concluida', CURRENT_DATE - INTERVAL '15 days' + TIME '10:00:00'),
(2, 1,  150.00, 'PIX', 'Concluida', CURRENT_DATE - INTERVAL '14 days' + TIME '14:30:00'),
(3, 4, 3000.00, 'TED', 'Concluida', CURRENT_DATE - INTERVAL '12 days' + TIME '09:15:00'),
(2, 3,  800.00, 'Boleto', 'Concluida', CURRENT_DATE - INTERVAL '10 days' + TIME '11:00:00'),
(1, 2,   50.00, 'PIX', 'Concluida', CURRENT_DATE - INTERVAL '5 days' + TIME '18:45:00');

-- -> Cenário B: Tentativa de Fraude (Conta 5 da Mariana fazendo picos de PIX rápidos)
-- Mariana tenta esvaziar a conta fazendo 3 transações suspeitas em um intervalo de menos de 10 min
INSERT INTO transacoes (conta_origem_id, conta_destino_id, valor, tipo_transacao, status, data_hora) VALUES
(5, 2,  4000.00, 'PIX', 'Concluida', CURRENT_DATE - INTERVAL '1 day' + TIME '23:01:00'),
(5, 3,  4500.00, 'PIX', 'Concluida', CURRENT_DATE - INTERVAL '1 day' + TIME '23:05:00'),
(5, 1,  3800.00, 'PIX', 'Concluida', CURRENT_DATE - INTERVAL '1 day' + TIME '23:08:00');

-- -> Cenário C: Conta Churn total
-- João (Conta 6) fez apenas uma transação há 6 meses atrás e sumiu da plataforma
INSERT INTO transacoes (conta_origem_id, conta_destino_id, valor, tipo_transacao, status, data_hora) VALUES
(6, 3,  200.00, 'PIX', 'Concluida', CURRENT_DATE - INTERVAL '180 days' + TIME '12:00:00');
