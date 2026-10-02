-- PostgreSQL Backup Automation Lab
-- Creates sample production-like data for backup and recovery testing.

CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
    account_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    account_number VARCHAR(30) UNIQUE NOT NULL,
    account_type VARCHAR(30) NOT NULL,
    balance NUMERIC(15,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(account_id),
    transaction_type VARCHAR(30) NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

CREATE INDEX idx_accounts_customer_id
    ON accounts(customer_id);

CREATE INDEX idx_transactions_account_id
    ON transactions(account_id);

CREATE INDEX idx_transactions_date
    ON transactions(transaction_date);

-- Customers
INSERT INTO customers
    (first_name, last_name, email)
VALUES
    ('Jean', 'Ndayemeye', 'jean@example.com'),
    ('John', 'Smith', 'john@example.com'),
    ('Sarah', 'Johnson', 'sarah@example.com'),
    ('David', 'Brown', 'david@example.com'),
    ('Emily', 'Wilson', 'emily@example.com');

-- Accounts
INSERT INTO accounts
    (customer_id, account_number, account_type, balance)
VALUES
    (1, 'ACC100001', 'CHECKING', 5000.00),
    (2, 'ACC100002', 'SAVINGS', 12500.00),
    (3, 'ACC100003', 'CHECKING', 3200.50),
    (4, 'ACC100004', 'SAVINGS', 8900.75),
    (5, 'ACC100005', 'CHECKING', 2100.25);

-- Transactions
INSERT INTO transactions
    (account_id, transaction_type, amount, description)
VALUES
    (1, 'DEPOSIT', 5000.00, 'Initial deposit'),
    (1, 'WITHDRAWAL', 250.00, 'ATM withdrawal'),
    (2, 'DEPOSIT', 12500.00, 'Initial deposit'),
    (2, 'WITHDRAWAL', 500.00, 'Bill payment'),
    (3, 'DEPOSIT', 3200.50, 'Initial deposit'),
    (4, 'DEPOSIT', 8900.75, 'Initial deposit'),
    (5, 'DEPOSIT', 2100.25, 'Initial deposit');

-- Verification output
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers
UNION ALL
SELECT 'accounts', COUNT(*)
FROM accounts
UNION ALL
SELECT 'transactions', COUNT(*)
FROM transactions;