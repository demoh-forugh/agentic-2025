-- Workshop Database Initialization
-- Creates multiple databases and sample tables for customer service and data processing demos

-- Create additional databases (POSTGRES_MULTIPLE_DATABASES doesn't work, so we do it manually)
SELECT 'CREATE DATABASE n8n_db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n_db')\gexec
SELECT 'CREATE DATABASE customer_data' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'customer_data')\gexec
SELECT 'CREATE DATABASE business_analytics' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'business_analytics')\gexec

-- Grant access to workshop user on all databases
GRANT ALL PRIVILEGES ON DATABASE n8n_db TO workshop;
GRANT ALL PRIVILEGES ON DATABASE customer_data TO workshop;
GRANT ALL PRIVILEGES ON DATABASE business_analytics TO workshop;

-- Customer Service Demo Tables
CREATE TABLE IF NOT EXISTS customer_tickets (
    id SERIAL PRIMARY KEY,
    customer_email VARCHAR(255) NOT NULL,
    subject VARCHAR(500) NOT NULL,
    message TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'open',
    category VARCHAR(100),
    sentiment_score DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customer_responses (
    id SERIAL PRIMARY KEY,
    ticket_id INTEGER REFERENCES customer_tickets(id),
    response_text TEXT NOT NULL,
    response_type VARCHAR(50) DEFAULT 'ai_generated',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Data Processing Demo Tables
CREATE TABLE IF NOT EXISTS sales_data (
    id SERIAL PRIMARY KEY,
    transaction_date DATE NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    region VARCHAR(100) NOT NULL,
    sales_rep VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS processed_reports (
    id SERIAL PRIMARY KEY,
    report_type VARCHAR(100) NOT NULL,
    report_data JSONB NOT NULL,
    generated_by VARCHAR(100) DEFAULT 'n8n_workflow',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample Data for Demos
INSERT INTO customer_tickets (customer_email, subject, message, priority, category) VALUES
('john.doe@example.com', 'Login Issues', 'I cannot access my account after the recent update. Please help.', 'high', 'technical_support'),
('jane.smith@example.com', 'Billing Question', 'I was charged twice for my subscription this month.', 'medium', 'billing'),
('bob.wilson@example.com', 'Feature Request', 'Would love to see dark mode added to the application.', 'low', 'feature_request'),
('alice.brown@example.com', 'Bug Report', 'The export function is not working properly in Chrome.', 'high', 'bug_report'),
('charlie.davis@example.com', 'General Inquiry', 'What are your business hours for phone support?', 'low', 'general');

INSERT INTO sales_data (transaction_date, customer_id, product_name, category, amount, region, sales_rep) VALUES
('2024-10-01', 'CUST001', 'Premium Software License', 'Software', 299.99, 'North America', 'Sarah Johnson'),
('2024-10-01', 'CUST002', 'Consulting Services', 'Services', 1500.00, 'Europe', 'Mike Chen'),
('2024-10-02', 'CUST003', 'Basic Software License', 'Software', 99.99, 'Asia Pacific', 'Lisa Wang'),
('2024-10-02', 'CUST004', 'Training Package', 'Training', 750.00, 'North America', 'Sarah Johnson'),
('2024-10-03', 'CUST005', 'Enterprise License', 'Software', 2999.99, 'Europe', 'Mike Chen');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customer_tickets_status ON customer_tickets(status);
CREATE INDEX IF NOT EXISTS idx_customer_tickets_priority ON customer_tickets(priority);
CREATE INDEX IF NOT EXISTS idx_customer_tickets_created_at ON customer_tickets(created_at);
CREATE INDEX IF NOT EXISTS idx_sales_data_date ON sales_data(transaction_date);
CREATE INDEX IF NOT EXISTS idx_sales_data_region ON sales_data(region);

-- Grant permissions for workshop user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO workshop;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO workshop;