CREATE TYPE appointment_status AS ENUM ('scheduled', 'cancelled', 'completed');

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY, 
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE doctors (
    doctor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE specialties (
    specialty_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE doctor_specialties (
    doctor_id INT NOT NULL,
    specialty_id INT NOT NULL,
    PRIMARY KEY (doctor_id, specialty_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id)
);

CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_time TIMESTAMP NOT NULL,
    status appointment_status DEFAULT 'scheduled',
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE appointment_audit (
    audit_id SERIAL PRIMARY KEY,
    appointment_id INT NOT NULL,
    action VARCHAR(20) NOT NULL,
    action_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE appointments
ADD CONSTRAINT uq_doctor_time UNIQUE (doctor_id, appointment_time);

CREATE INDEX idx_appointments_doctor_time
ON appointments (doctor_id, appointment_time);

INSERT INTO patients(first_name, last_name, email, phone) VALUES
('Ana', 'Pop', 'anapop@gmail.com', '0721567601'),
('Mihai', 'Ionescu', 'mihaiionescu@gmail.com', '0721562236'),
('Maria', 'Popa', 'mariapopa@yahoo.com', '0721078523'),
('Alex', 'Marin', 'alexmarin@gmail.com', '0721345004'),
('Ioana', 'Stan', 'ioanastan@yahoo.com', '0721776985'),
('Andrei', 'Dima', 'andreidima@gmail.com', '0721456789'),
('Elena', 'Rusu', 'elenarusu@yahoo.com', '0721234567'),
('Bogdan', 'Nica', 'bogdannica@gmail.com', '0721987654');

INSERT INTO doctors(first_name, last_name, email, phone) VALUES
('Ioan', 'Marin', 'dr.marin@clinic.com', '0721000010'),
('Elena', 'Pop', 'dr.pop@clinic.com', '0721000011'),
('Andrei', 'Ion', 'dr.ion@clinic.com', '0721000012'),
('Raluca', 'Gheorghe', 'dr.gheorghe@clinic.com', '0721000013');

INSERT INTO specialties(name) VALUES
('Cardiology'),
('Neurology'),
('Dermatology'),
('Pediatrics'),
('Orthopedics'),
('Ophthalmology');

INSERT INTO doctor_specialties(doctor_id, specialty_id) VALUES
(1, 1),
(1, 2),
(2, 3),
(2, 6),
(3, 4),
(4, 5);

INSERT INTO appointments(patient_id, doctor_id, appointment_time) VALUES
(1, 1, '2026-04-01 09:00:00'),
(2, 1, '2026-04-01 10:00:00'),
(3, 2, '2026-04-01 11:00:00'),
(4, 3, '2026-04-02 09:00:00'),
(5, 4, '2026-04-02 10:30:00'),
(6, 1, '2026-04-03 14:00:00'),
(7, 2, '2026-04-03 15:00:00'),
(8, 3, '2026-04-04 09:00:00'),
(1, 4, '2026-04-05 11:00:00'),
(2, 3, '2026-04-05 14:30:00');

CREATE OR REPLACE FUNCTION schedule_appointment(
    p_patient_id INT,
    p_doctor_id INT,
    p_time TIMESTAMP
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_time < CURRENT_TIMESTAMP THEN
        RETURN 'Appointment time must be in the future';
    END IF;

    INSERT INTO appointments(patient_id, doctor_id, appointment_time)
    VALUES (p_patient_id, p_doctor_id, p_time);

    RETURN 'Appointment scheduled';

EXCEPTION
    WHEN unique_violation THEN
        RETURN 'This time slot is already booked';
    WHEN foreign_key_violation THEN
        RETURN 'Invalid patient or doctor id';
END;
$$;

CREATE OR REPLACE FUNCTION cancel_appointment(p_appointment_id INT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE appointments
    SET status = 'cancelled'
    WHERE appointment_id = p_appointment_id
      AND status = 'scheduled';

    IF NOT FOUND THEN
        RETURN 'Appointment not found or already cancelled';
    END IF;

    RETURN 'Appointment cancelled successfully';
END;
$$;

CREATE OR REPLACE FUNCTION get_doctor_appointments(p_doctor_id INT)
RETURNS TABLE (
    patient_name TEXT,
    appointment_time TIMESTAMP,
    status appointment_status
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.first_name || ' ' || p.last_name,
        a.appointment_time,
        a.status
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE a.doctor_id = p_doctor_id
    ORDER BY a.appointment_time;
END;
$$;

CREATE OR REPLACE FUNCTION get_available_doctors(p_time TIMESTAMP)
RETURNS TABLE (doctor_name TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT d.first_name || ' ' || d.last_name
    FROM doctors d
    WHERE d.doctor_id NOT IN (
        SELECT doctor_id FROM appointments
        WHERE appointment_time = p_time
        AND status = 'scheduled'
    );
END;
$$;

CREATE OR REPLACE FUNCTION log_appointment_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO appointment_audit(appointment_id, action)
    VALUES (NEW.appointment_id, 'INSERT');
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION log_appointment_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO appointment_audit(appointment_id, action)
    VALUES (NEW.appointment_id, 'UPDATE');
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_log_appointment_insert
AFTER INSERT ON appointments
FOR EACH ROW
EXECUTE FUNCTION log_appointment_insert();

CREATE TRIGGER trg_log_appointment_update
AFTER UPDATE ON appointments
FOR EACH ROW
EXECUTE FUNCTION log_appointment_update();

CREATE VIEW doctor_schedule AS
SELECT 
    a.appointment_id,
    d.first_name || ' ' || d.last_name AS doctor,
    p.first_name || ' ' || p.last_name AS patient,
    a.appointment_time,
    a.status
FROM appointments a
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN patients p ON a.patient_id = p.patient_id;

CREATE VIEW upcoming_appointments AS
SELECT 
    a.appointment_id,
    d.first_name || ' ' || d.last_name AS doctor,
    p.first_name || ' ' || p.last_name AS patient,
    a.appointment_time
FROM appointments a
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN patients p ON a.patient_id = p.patient_id
WHERE a.status = 'scheduled'
AND a.appointment_time > CURRENT_TIMESTAMP
ORDER BY a.appointment_time;

CREATE VIEW doctor_appointment_summary AS
SELECT
    d.first_name || ' ' || d.last_name AS doctor,
    COUNT(a.appointment_id) AS total,
    SUM(CASE WHEN a.status = 'scheduled'  THEN 1 ELSE 0 END) AS scheduled,
    SUM(CASE WHEN a.status = 'completed'  THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN a.status = 'cancelled'  THEN 1 ELSE 0 END) AS cancelled
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name;

SELECT schedule_appointment(1, 1, '2026-05-06 10:00:00');
SELECT schedule_appointment(2, 1, '2026-05-06 10:00:00');
SELECT schedule_appointment(1, 1, '2020-01-01 09:00:00');

UPDATE appointments
SET status = 'completed'
WHERE appointment_id = 1;

SELECT * FROM doctor_schedule;
SELECT * FROM upcoming_appointments;
SELECT * FROM doctor_appointment_summary;

SELECT 
    d.doctor_id,
    d.first_name,
    d.last_name,
    COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY total_appointments DESC;

SELECT
    d.doctor_id,
    d.first_name || ' ' || d.last_name AS doctor,
    a.status,
    COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name, a.status
ORDER BY doctor, total_appointments DESC;

SELECT
    DATE(appointment_time) AS appointment_day,
    COUNT(*) AS total_appointments
FROM appointments
GROUP BY DATE(appointment_time)
ORDER BY total_appointments DESC, appointment_day ASC;

SELECT * FROM appointment_audit
ORDER BY audit_id DESC;

SELECT cancel_appointment(1);
SELECT * FROM get_doctor_appointments(1);
SELECT * FROM get_available_doctors('2026-05-06 10:00:00');
