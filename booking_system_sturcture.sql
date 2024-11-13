-- Create Users Table with GDPR Compliance
CREATE TABLE abc123_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,  -- 'admin' or 'reserver'
    age INT NOT NULL,
    consent BOOLEAN NOT NULL,  -- Consent for data usage
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP  -- Soft delete to maintain historical data
);

-- Create Resources Table with Description Encrypted
CREATE TABLE abc123_resources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description BYTEA,  -- Encrypted field
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP  -- Soft delete to maintain historical data
);

-- Create Reservations Table without Personal Identifiers
CREATE TABLE abc123_reservations (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    resource_id INT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,  -- Soft delete to maintain historical data
    FOREIGN KEY (user_id) REFERENCES abc123_users (id),
    FOREIGN KEY (resource_id) REFERENCES abc123_resources (id)
);

-- Encrypt Sensitive Data
CREATE FUNCTION encrypt_description() RETURNS trigger AS $$
BEGIN
    NEW.description := pgp_sym_encrypt(NEW.description, 'encryption_key');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER encrypt_desc BEFORE INSERT OR UPDATE ON abc123_resources
FOR EACH ROW EXECUTE FUNCTION encrypt_description();

-- Decrypt Sensitive Data
CREATE FUNCTION decrypt_description(description BYTEA) RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(description, 'encryption_key');
END;
$$ LANGUAGE plpgsql;

-- Function to Retrieve Resources with Decrypted Description
CREATE OR REPLACE VIEW public_resources AS 
SELECT id, name, decrypt_description(description) AS description
FROM abc123_resources;

-- Create Functions and Triggers for age verification
CREATE FUNCTION check_user_age() RETURNS trigger AS $$
BEGIN
    IF (SELECT age FROM abc123_users WHERE id = NEW.user_id) < 15 THEN
        RAISE EXCEPTION 'User must be at least 15 years old to book a resource';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER age_check BEFORE INSERT ON abc123_reservations
FOR EACH ROW EXECUTE FUNCTION check_user_age();
