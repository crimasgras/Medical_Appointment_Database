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
