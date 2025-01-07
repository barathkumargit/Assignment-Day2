-- Create Customers table
CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    address VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create Categories table
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

-- Create Products table
CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) CHECK (price > 0),
    stock INT CHECK (stock >= 0),
    category_id INT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- Create Orders table
CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- Create Order_Items table
CREATE TABLE Order_Items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT CHECK (quantity > 0),
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Insert sample categories
INSERT INTO Categories (category_name) VALUES
('Smartphones'), ('Laptops'), ('Accessories'), ('Tablets'), ('Cameras');

-- Insert sample products
INSERT INTO Products (product_name, description, price, stock, category_id) VALUES
('iPhone 14', 'Latest Apple smartphone', 999.99, 15, 1),
('Samsung Galaxy S22', 'Flagship Samsung phone', 899.99, 20, 1),
('MacBook Air', 'Lightweight Apple laptop', 1299.99, 5, 2),
('Dell XPS 13', 'High-performance laptop', 1199.99, 8, 2),
('Bluetooth Headphones', 'Wireless audio device', 199.99, 50, 3),
('iPad Air', 'Apple tablet', 599.99, 10, 4),
('Sony A7 Camera', 'Professional camera', 1999.99, 7, 5),
('Camera Tripod', 'Sturdy tripod', 49.99, 25, 5),
('USB-C Cable', 'Fast charging cable', 19.99, 30, 3),
('Laptop Stand', 'Adjustable laptop stand', 39.99, 12, 3);

-- Insert sample customers
INSERT INTO Customers (first_name, last_name, email, phone, address) VALUES
('Barath', 'Doe', 'barath.doe@example.com', '1234567890', '123 Elm Street'),
('Ravi', 'Smith', 'ravi.smith@example.com', '9876543210', '456 Oak Avenue'),
('Arun', 'Johnson', 'arun.johnson@example.com', '1112223333', '789 Pine Road'),
('Vicky', 'Brown', 'vicky.brown@example.com', '4445556666', '101 Maple Lane'),
('Siva', 'Davis', 'siva.davis@example.com', '7778889999', '202 Birch Blvd'),
('Arun', 'Evans', 'arun.evans@example.com', '3334445555', '303 Cedar Street'),
('Praveen', 'Foster', 'praveen.foster@example.com', '8889990000', '404 Spruce Drive'),
('Kumar', 'Green', 'kumar.green@example.com', '5556667777', '505 Willow Way');

-- Insert sample orders
INSERT INTO Orders (customer_id, order_date) VALUES
(1, '2025-01-01 10:00:00'),
(2, '2025-01-02 11:30:00'),
(3, '2025-01-03 14:45:00'),
(4, '2025-01-04 16:20:00');

-- Insert sample order items
INSERT INTO Order_Items (order_id, product_id, quantity, price) VALUES
(1, 1, 1, 999.99),
(1, 5, 2, 199.99),
(2, 3, 1, 1299.99),
(2, 7, 1, 1999.99),
(3, 4, 2, 1199.99),
(3, 8, 1, 49.99),
(4, 6, 1, 599.99),
(4, 10, 2, 39.99);

-- Find Top 3 Customers by Order Value
SELECT 
    c.customer_id, 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
    SUM(oi.quantity * oi.price) AS total_order_value
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id
ORDER BY total_order_value DESC
LIMIT 3;

-- List Products with Low Stock (Below 10)
SELECT 
    product_id, 
    product_name, 
    stock 
FROM Products
WHERE stock < 10;

-- Calculate Revenue by Category
SELECT 
    cat.category_name, 
    SUM(oi.quantity * oi.price) AS total_revenue
FROM Categories cat
JOIN Products p ON cat.category_id = p.category_id
JOIN Order_Items oi ON p.product_id = oi.product_id
GROUP BY cat.category_name
ORDER BY total_revenue DESC;

-- Show Orders with Items and Total Amount
SELECT 
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    o.order_date,
    SUM(oi.quantity * oi.price) AS total_order_amount
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY o.order_id;

-- Advanced Tasks: View - order_summary
CREATE VIEW order_summary AS
SELECT 
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT oi.product_id) AS unique_products_count,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.quantity * oi.price) AS total_order_amount,
    o.order_date
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
GROUP BY o.order_id;

-- Stored Procedure: Update Stock Levels
DELIMITER $$

CREATE PROCEDURE update_stock_level(IN p_product_id INT, IN p_quantity INT)
BEGIN
    UPDATE Products
    SET stock = stock - p_quantity
    WHERE product_id = p_product_id;
END $$

DELIMITER ;

-- Trigger on Insert (to update stock when a new order item is added)
DELIMITER $$

CREATE TRIGGER update_stock_on_insert
AFTER INSERT ON Order_Items
FOR EACH ROW
BEGIN
    CALL update_stock_level(NEW.product_id, NEW.quantity);
END $$

DELIMITER ;

-- Trigger on Delete (to update stock when an order item is deleted)
DELIMITER $$

CREATE TRIGGER update_stock_on_delete
AFTER DELETE ON Order_Items
FOR EACH ROW
BEGIN
    CALL update_stock_level(OLD.product_id, -OLD.quantity);
END $$

DELIMITER ;
