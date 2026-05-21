CREATE DATABASE IF NOT EXISTS railway_booking2;
USE railway_booking2;

-- 1. Станции
CREATE TABLE Stations (
    station_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    station_code VARCHAR(6) UNIQUE,
    city VARCHAR(50),
    region VARCHAR(50),
    min_transfer_time TIME DEFAULT '00:30:00' -- Новое поле для расчета пересадок
);

-- 2. Пользователи
CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'blocked', 'pending') DEFAULT 'active'
);

-- 3. Пассажиры
CREATE TABLE Passengers (
    passenger_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    birth_date DATE,
    doc_type VARCHAR(20),
    doc_series VARCHAR(10),
    doc_number VARCHAR(10),
    phone VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL
);

-- 4. Маршруты (Географическая схема)
CREATE TABLE Routes (
    route_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    distance_km INT,
    start_station_id INT,
    end_station_id INT,
    FOREIGN KEY (start_station_id) REFERENCES Stations(station_id),
    FOREIGN KEY (end_station_id) REFERENCES Stations(station_id)
);

-- 5. Поезда (Техническая единица)
CREATE TABLE Trains (
    train_id INT PRIMARY KEY AUTO_INCREMENT,
    number VARCHAR(10) UNIQUE NOT NULL, -- Номер поезда (напр. 002Й)
    name VARCHAR(100),
    train_type ENUM('fast', 'suburban', 'express')
    -- route_id удален, так как поезд может менять маршруты в разных рейсах
);

-- 6. Рейсы (Событие поездки на конкретную дату)
CREATE TABLE Voyages (
    voyage_id INT PRIMARY KEY AUTO_INCREMENT,
    train_id INT,
    route_id INT,
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    status ENUM('planned', 'on_boarding', 'in_transit', 'arrived', 'cancelled') DEFAULT 'planned',
    FOREIGN KEY (train_id) REFERENCES Trains(train_id),
    FOREIGN KEY (route_id) REFERENCES Routes(route_id)
);

-- 7. Типы вагонов
CREATE TABLE Car_Types (
    car_type_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL, -- Купе, Плацкарт и т.д.
    seat_count INT
);

-- 8. Вагоны
CREATE TABLE Cars (
    car_id INT PRIMARY KEY AUTO_INCREMENT,
    train_id INT,
    car_type_id INT,
    car_number INT,
    floors ENUM('1', '2') DEFAULT '1',
    FOREIGN KEY (train_id) REFERENCES Trains(train_id),
    FOREIGN KEY (car_type_id) REFERENCES Car_Types(car_type_id)
);

-- 9. Места (Физическое описание)
CREATE TABLE Seats (
    seat_id INT PRIMARY KEY AUTO_INCREMENT,
    car_id INT,
    seat_number INT NOT NULL,
    seat_type ENUM('lower', 'upper', 'side_lower', 'side_upper'),
    -- Статус теперь только физический (сломано/исправно)
    is_operable BOOLEAN DEFAULT TRUE, 
    FOREIGN KEY (car_id) REFERENCES Cars(car_id)
);

-- 10. Тарифы (Цена теперь зависит от Рейса)
CREATE TABLE Tariffs (
    tariff_id INT PRIMARY KEY AUTO_INCREMENT,
    voyage_id INT, -- Теперь привязано к рейсу, а не к маршруту
    car_type_id INT,
    base_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (voyage_id) REFERENCES Voyages(voyage_id),
    FOREIGN KEY (car_type_id) REFERENCES Car_Types(car_type_id)
);

-- 11. Заказы
CREATE TABLE Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'paid', 'cancelled', 'refunded') DEFAULT 'pending',
    total_amount DECIMAL(10,2),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- 12. Платежи
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    method ENUM('card', 'sbp', 'wallet'),
    status ENUM('success', 'failed', 'processing'),
    transaction_id VARCHAR(50) UNIQUE,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

-- 13. Билеты (Сегментированные и связанные)
CREATE TABLE Tickets (
    ticket_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    passenger_id INT,
    voyage_id INT, -- Привязка к конкретному рейсу
    seat_id INT,
    departure_station_id INT,
    arrival_station_id INT,
    segment_number INT DEFAULT 1, -- Порядок сегмента при пересадке
    related_ticket_id INT NULL, -- Ссылка на следующий сегмент пересадки
    price DECIMAL(10,2),
    status ENUM('valid', 'used', 'cancelled'),
    qr_code VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (passenger_id) REFERENCES Passengers(passenger_id),
    FOREIGN KEY (voyage_id) REFERENCES Voyages(voyage_id),
    FOREIGN KEY (seat_id) REFERENCES Seats(seat_id),
    FOREIGN KEY (departure_station_id) REFERENCES Stations(station_id),
    FOREIGN KEY (arrival_station_id) REFERENCES Stations(station_id),
    FOREIGN KEY (related_ticket_id) REFERENCES Tickets(ticket_id)
);