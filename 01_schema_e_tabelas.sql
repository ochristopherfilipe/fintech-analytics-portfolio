-- ====================================================================================
-- PROJETO FINTECH ANALYTICS PORTFOLIO
-- Arquivo: 01_schema_e_tabelas.sql
-- Descrição: DDL do Banco de Dados para a Fintech Fictícia
-- ====================================================================================

-- Tabela de Clientes
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(20) UNIQUE NOT NULL,
    tipo_cliente VARCHAR(2) CHECK (tipo_cliente IN ('PF', 'PJ')),
    data_cadastro DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Ativo'
);

-- Tabela de Contas (Um cliente pode ter múltiplas contas, ex: corrente e investimento)
CREATE TABLE contas (
    conta_id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(cliente_id),
    saldo DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    limite_credito DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    tipo_conta VARCHAR(50) CHECK (tipo_conta IN ('Corrente', 'Poupanca', 'Investimento')),
    data_abertura DATE NOT NULL
);

-- Tabela de Transações 
-- (Pode envolver duas contas no sistema ou uma conta e uma entidade externa, caso nulo)
CREATE TABLE transacoes (
    transacao_id SERIAL PRIMARY KEY,
    conta_origem_id INT REFERENCES contas(conta_id),
    conta_destino_id INT REFERENCES contas(conta_id),
    valor DECIMAL(15, 2) NOT NULL,
    tipo_transacao VARCHAR(50) CHECK (tipo_transacao IN ('PIX', 'TED', 'Cartao_Credito', 'Boleto')),
    status VARCHAR(20) CHECK (status IN ('Concluida', 'Falhada', 'Estornada')),
    data_hora TIMESTAMP NOT NULL
);

-- Indices para otimização em tabelas gigantescas (simulando cenário real)
CREATE INDEX idx_transacoes_data_hora ON transacoes(data_hora);
CREATE INDEX idx_transacoes_origem ON transacoes(conta_origem_id);
CREATE INDEX idx_transacoes_destino ON transacoes(conta_destino_id);
