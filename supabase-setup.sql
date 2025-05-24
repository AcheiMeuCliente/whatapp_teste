-- Script para configurar o banco de dados Supabase
-- Execute este script no SQL Editor do seu painel Supabase

-- Criar tabela de usuários
CREATE TABLE IF NOT EXISTS "users" (
  "id" serial PRIMARY KEY NOT NULL,
  "email" text NOT NULL UNIQUE,
  "password" text NOT NULL,
  "full_name" text NOT NULL,
  "created_at" timestamp DEFAULT now() NOT NULL
);

-- Criar tabela de contatos
CREATE TABLE IF NOT EXISTS "contacts" (
  "id" serial PRIMARY KEY NOT NULL,
  "user_id" integer NOT NULL REFERENCES users(id),
  "name" text NOT NULL,
  "phone" text NOT NULL,
  "email" text,
  "company" text,
  "status" text DEFAULT 'active' NOT NULL,
  "last_message_sent" timestamp,
  "created_at" timestamp DEFAULT now() NOT NULL
);

-- Criar tabela de templates de mensagem
CREATE TABLE IF NOT EXISTS "message_templates" (
  "id" serial PRIMARY KEY NOT NULL,
  "user_id" integer NOT NULL REFERENCES users(id),
  "name" text NOT NULL,
  "content" text NOT NULL,
  "category" text NOT NULL,
  "priority" text DEFAULT 'normal' NOT NULL,
  "usage_count" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp DEFAULT now() NOT NULL
);

-- Criar tabela de campanhas
CREATE TABLE IF NOT EXISTS "campaigns" (
  "id" serial PRIMARY KEY NOT NULL,
  "user_id" integer NOT NULL REFERENCES users(id),
  "name" text NOT NULL,
  "template_id" integer NOT NULL REFERENCES message_templates(id),
  "status" text DEFAULT 'pending' NOT NULL,
  "scheduled_at" timestamp,
  "completed_at" timestamp,
  "total_contacts" integer DEFAULT 0 NOT NULL,
  "messages_sent" integer DEFAULT 0 NOT NULL,
  "messages_delivered" integer DEFAULT 0 NOT NULL,
  "messages_read" integer DEFAULT 0 NOT NULL,
  "messages_replied" integer DEFAULT 0 NOT NULL,
  "sending_speed" text DEFAULT 'normal' NOT NULL,
  "created_at" timestamp DEFAULT now() NOT NULL
);

-- Criar tabela de contatos de campanha
CREATE TABLE IF NOT EXISTS "campaign_contacts" (
  "id" serial PRIMARY KEY NOT NULL,
  "campaign_id" integer NOT NULL REFERENCES campaigns(id),
  "contact_id" integer NOT NULL REFERENCES contacts(id),
  "status" text DEFAULT 'pending' NOT NULL,
  "sent_at" timestamp,
  "delivered_at" timestamp,
  "read_at" timestamp,
  "replied_at" timestamp,
  "error_message" text
);

-- Criar usuário de demonstração
-- Senha: demo123 (hash bcrypt correto)
INSERT INTO users (email, password, full_name)
VALUES ('demo@whatsapp-sender.com', '$2b$10$ZBPW0ODju9zH.gM9vtHFr.KWr0khezHFbQqX3iv6fGFXUHQBTsNii', 'Usuário Demo')
ON CONFLICT (email) DO NOTHING;

-- Inserir dados de exemplo (apenas se o usuário demo existir)
DO $$
DECLARE
    demo_user_id integer;
    template_id integer;
BEGIN
    -- Buscar ID do usuário demo
    SELECT id INTO demo_user_id FROM users WHERE email = 'demo@whatsapp-sender.com';
    
    IF demo_user_id IS NOT NULL THEN
        -- Inserir contatos de exemplo
        INSERT INTO contacts (user_id, name, phone, email, company, status, last_message_sent)
        VALUES 
          (demo_user_id, 'João Silva', '+5511999887766', 'joao@empresa.com', 'Empresa ABC', 'active', NOW() - INTERVAL '1 day'),
          (demo_user_id, 'Maria Santos', '+5511888776655', 'maria@loja.com', 'Loja XYZ', 'active', NOW() - INTERVAL '12 hours'),
          (demo_user_id, 'Carlos Oliveira', '+5511777665544', null, null, 'pending', null)
        ON CONFLICT DO NOTHING;

        -- Inserir templates de exemplo
        INSERT INTO message_templates (user_id, name, content, category, priority, usage_count)
        VALUES 
          (demo_user_id, 'Boas-vindas', 'Olá {nome}! 👋 Bem-vindo(a) à nossa empresa. Estamos muito felizes em tê-lo(a) conosco!', 'saudacao', 'high', 15),
          (demo_user_id, 'Promoção Especial', 'Oi {nome}! 🎉 Temos uma oferta especial só para você: 20% de desconto em todos os produtos. Use o código PROMO20 até o final do mês!', 'promocao', 'normal', 8),
          (demo_user_id, 'Lembrete de Reunião', 'Olá {nome}, lembro que temos nossa reunião marcada para amanhã às 14h. Confirma sua presença? 📅', 'lembrete', 'high', 3)
        ON CONFLICT DO NOTHING;

        -- Buscar ID do primeiro template
        SELECT id INTO template_id FROM message_templates WHERE user_id = demo_user_id LIMIT 1;
        
        IF template_id IS NOT NULL THEN
            -- Inserir campanha de exemplo
            INSERT INTO campaigns (user_id, name, template_id, status, scheduled_at, completed_at, total_contacts, messages_sent, messages_delivered, messages_read, messages_replied, sending_speed)
            VALUES 
              (demo_user_id, 'Campanha de Boas-vindas Q4', template_id, 'completed', NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days', 50, 48, 45, 38, 12, 'normal')
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;
END $$;

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_contacts_user_id ON contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_templates_user_id ON message_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_user_id ON campaigns(user_id);
CREATE INDEX IF NOT EXISTS idx_campaign_contacts_campaign_id ON campaign_contacts(campaign_id);

-- Comentário final
SELECT 'Banco de dados configurado com sucesso!' as message;