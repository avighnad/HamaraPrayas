-- Hamara Prayas Database Schema
-- This file contains the SQL schema for the backend database

-- Users table for authentication and profiles
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    blood_type VARCHAR(5) CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    date_of_birth DATE,
    is_donor BOOLEAN DEFAULT false,
    last_donation_date DATE,
    profile_image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Emergency contacts for users
CREATE TABLE emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Blood banks and medical facilities
CREATE TABLE blood_banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    website TEXT,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    operating_hours TEXT,
    is_open BOOLEAN DEFAULT true,
    rating DECIMAL(3, 2) CHECK (rating >= 0 AND rating <= 5),
    facility_type VARCHAR(50) DEFAULT 'hospital',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Blood inventory at each facility
CREATE TABLE blood_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blood_bank_id UUID REFERENCES blood_banks(id) ON DELETE CASCADE,
    blood_type VARCHAR(5) NOT NULL CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    units_available INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(blood_bank_id, blood_type)
);

-- Blood requests from users
CREATE TABLE blood_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    patient_name VARCHAR(100) NOT NULL,
    blood_type VARCHAR(5) NOT NULL CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    units_needed INTEGER NOT NULL CHECK (units_needed > 0),
    urgency VARCHAR(20) NOT NULL CHECK (urgency IN ('Low', 'Medium', 'High')),
    hospital VARCHAR(255) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    additional_notes TEXT,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Fulfilled', 'Cancelled')),
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Blood donations
CREATE TABLE blood_donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_id UUID REFERENCES users(id) ON DELETE CASCADE,
    blood_bank_id UUID REFERENCES blood_banks(id) ON DELETE CASCADE,
    blood_type VARCHAR(5) NOT NULL CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    units_donated INTEGER NOT NULL DEFAULT 1,
    donation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    next_eligible_date DATE,
    notes TEXT
);

-- User sessions for authentication
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Password reset tokens
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Blood bank reviews and ratings
CREATE TABLE blood_bank_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    blood_bank_id UUID REFERENCES blood_banks(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, blood_bank_id)
);

-- Notifications for users
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_blood_banks_location ON blood_banks(latitude, longitude);
CREATE INDEX idx_blood_requests_user_id ON blood_requests(user_id);
CREATE INDEX idx_blood_requests_status ON blood_requests(status);
CREATE INDEX idx_blood_inventory_blood_bank_id ON blood_inventory(blood_bank_id);
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token_hash ON user_sessions(token_hash);

-- Triggers for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blood_banks_updated_at BEFORE UPDATE ON blood_banks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blood_requests_updated_at BEFORE UPDATE ON blood_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sample data insertion
INSERT INTO blood_banks (name, address, phone_number, email, website, latitude, longitude, operating_hours, rating, facility_type) VALUES
('City General Hospital', '123 Main Street, City Center', '+1-555-0123', 'bloodbank@cityhospital.com', 'https://cityhospital.com', 37.7749, -122.4194, '24/7', 4.5, 'hospital'),
('Red Cross Blood Center', '456 Oak Avenue, Downtown', '+1-555-0456', 'donate@redcross.org', 'https://redcross.org/blood', 37.7833, -122.4167, 'Mon-Fri 8AM-6PM, Sat 9AM-4PM', 4.8, 'clinic'),
('Community Medical Center', '789 Pine Street, Westside', '+1-555-0789', 'blood@communitymed.com', 'https://communitymed.com', 37.7849, -122.4094, 'Mon-Sun 7AM-10PM', 4.2, 'hospital');

-- Insert sample blood inventory
INSERT INTO blood_inventory (blood_bank_id, blood_type, units_available) VALUES
((SELECT id FROM blood_banks WHERE name = 'City General Hospital'), 'A+', 15),
((SELECT id FROM blood_banks WHERE name = 'City General Hospital'), 'A-', 8),
((SELECT id FROM blood_banks WHERE name = 'City General Hospital'), 'B+', 12),
((SELECT id FROM blood_banks WHERE name = 'City General Hospital'), 'B-', 6),
((SELECT id FROM blood_banks WHERE name = 'City General Hospital'), 'AB+', 4),
((SELECT id FROM blood_banks WHERE name = 'City General Hospital'), 'AB-', 2),
((SELECT id FROM blood_banks WHERE name = 'City General Hospital'), 'O+', 25),
((SELECT id FROM blood_banks WHERE name = 'City General Hospital'), 'O-', 10);

-- Views for common queries
CREATE VIEW nearby_blood_banks AS
SELECT 
    bb.*,
    ST_Distance(
        ST_MakePoint(bb.longitude, bb.latitude)::geography,
        ST_MakePoint($1, $2)::geography
    ) as distance_meters
FROM blood_banks bb
WHERE ST_DWithin(
    ST_MakePoint(bb.longitude, bb.latitude)::geography,
    ST_MakePoint($1, $2)::geography,
    $3
)
ORDER BY distance_meters;

CREATE VIEW blood_bank_inventory_summary AS
SELECT 
    bb.id,
    bb.name,
    bb.address,
    bb.rating,
    COUNT(bi.blood_type) as blood_types_available,
    SUM(bi.units_available) as total_units
FROM blood_banks bb
LEFT JOIN blood_inventory bi ON bb.id = bi.blood_bank_id
GROUP BY bb.id, bb.name, bb.address, bb.rating;

-- Comments
COMMENT ON TABLE users IS 'User accounts and profiles';
COMMENT ON TABLE blood_banks IS 'Medical facilities and blood banks';
COMMENT ON TABLE blood_inventory IS 'Current blood inventory at each facility';
COMMENT ON TABLE blood_requests IS 'Blood requests from users';
COMMENT ON TABLE blood_donations IS 'Blood donation records';
COMMENT ON TABLE user_sessions IS 'User authentication sessions';
COMMENT ON TABLE notifications IS 'User notifications and alerts';

