-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 24, 2024 at 06:34 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `addCategoryAndLog` (IN `p_category_name` VARCHAR(255), IN `p_user_id` INT, OUT `out_category_id` INT)   BEGIN
    DECLARE v_category_id INT;
    DECLARE v_product_id INT DEFAULT NULL;
    DECLARE v_is_avalible BOOLEAN DEFAULT TRUE; 
    
    INSERT INTO category (category_name)
    VALUES (p_category_name);

    SET v_category_id = LAST_INSERT_ID();

    INSERT INTO log (user_id, action, details)
    VALUES (p_user_id, 'Add Category', CONCAT('Added category: ', p_category_name, ' with ID: ', v_category_id));
	SET out_category_id = v_category_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AddOrUpdateCategory` (IN `p_category_name` VARCHAR(255), IN `p_product_id` INT, IN `p_user_id` INT)   BEGIN
    DECLARE v_category_id INT;

    SELECT category_id INTO v_category_id
    FROM category
    WHERE category_name = p_category_name
      AND product_id IS NULL
    LIMIT 1;

    IF v_category_id IS NOT NULL THEN
        UPDATE category
        SET product_id = p_product_id
        WHERE category_id = v_category_id;

        INSERT INTO log (user_id, action, details)
        VALUES (p_user_id, 'Update Category', 
                CONCAT('Updated category: ', p_category_name, 
                       ' with new product_id: ', p_product_id));
    ELSE
        INSERT INTO category (category_name, product_id, is_avalible)
        VALUES (p_category_name, p_product_id, TRUE);

        SET v_category_id = LAST_INSERT_ID();

        INSERT INTO log (user_id, action, details)
        VALUES (p_user_id, 'Add Category', 
                CONCAT('Added new category: ', p_category_name, 
                       ' with product_id: ', p_product_id));
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addUD` (IN `in_user_id` INT, IN `in_phone` VARCHAR(20), IN `in_street1` VARCHAR(50), IN `in_street2` VARCHAR(50), IN `in_pincode` VARCHAR(12), IN `in_city` VARCHAR(50), IN `in_state` VARCHAR(50), IN `in_country` VARCHAR(50), OUT `out_address_id` INT)   BEGIN
INSERT INTO user_details (user_id,phone,street1,street2, pincode, city, state, country) 
VALUES (in_user_id,in_phone, in_street1, in_street2,in_pincode ,in_city,in_state,in_country );

SELECT LAST_INSERT_ID() INTO out_address_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createAccount` (IN `p_e_mail` VARCHAR(50), IN `p_f_name` VARCHAR(50), IN `p_l_name` VARCHAR(50), IN `p_username` VARCHAR(50), IN `p_password` VARCHAR(50))   BEGIN
    DECLARE v_user_id INT;
    DECLARE v_action VARCHAR(255);
    DECLARE v_details TEXT;

    INSERT INTO user (e_mail, f_name, l_name, username, password)
    VALUES (p_e_mail, p_f_name, p_l_name, p_username, p_password);

    SET v_user_id = LAST_INSERT_ID();

    -- Prepare log details
    SET v_action = 'Create Account';
    SET v_details = CONCAT('Created user account for ', p_username);

    -- Insert into log table
    INSERT INTO log (user_id, action, action_timestamp, details)
    VALUES (v_user_id, v_action, NOW(), v_details);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_category` (IN `in_category_name` VARCHAR(50), IN `in_user_id` INT)   BEGIN    

	DELETE FROM category WHERE category_name = in_category_name;
    
    INSERT INTO log (user_id, action, details)
    VALUES (
        in_user_id,
        'DELETE Category',
        CONCAT('Deleted Category Name = ', in_category_name)
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `delete_product` (IN `productID` INT, IN `userID` INT)   BEGIN
	DECLARE p_name varchar(50);
	DECLARE p_price decimal(10,0);
	DECLARE p_color varchar(50);
	DECLARE p_description text;
    
    SELECT name,price,color,description INTO p_name,p_price,p_color,p_description 
    FROM product 
    WHERE product_id =productID;    
    
	DELETE FROM category WHERE product_id = productID;
    DELETE FROM product WHERE product_id = productID;
    
    INSERT INTO log (user_id, action, details)
    VALUES (
        userID,
        'DELETE Product',
        CONCAT('Deleted Product: ','ID = ', productID, ', ','Name = ', p_name, ', ','Price = ', p_price, ', ','Color = ', p_color, ', ','Description = ', p_description)
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertProduct` (IN `p_name` VARCHAR(255), IN `p_price` DECIMAL(10,2), IN `p_available_count` INT, IN `p_in_stock` BOOLEAN, IN `p_color` VARCHAR(50), IN `p_available_unit` VARCHAR(50), IN `p_description` TEXT, OUT `p_product_id` INT, IN `userID` INT)   BEGIN
    INSERT INTO product (
        name, price, available_count, in_stock, color, available_unit, description
    )
    VALUES (
        p_name, p_price, p_available_count, p_in_stock, p_color, p_available_unit, p_description
    );
    SET p_product_id = LAST_INSERT_ID();
    INSERT INTO log(user_id,action,details) VALUES (userID,'Add Product',CONCAT('Add product with product_id : ',p_product_id));
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `login` (IN `in_username` VARCHAR(50), IN `in_password` VARCHAR(50), OUT `out_type` VARCHAR(100), OUT `out_user_id` INT)   BEGIN
    DECLARE v_user_id INT;
    DECLARE v_user_exists BOOLEAN;
    SELECT user_id,user_id,user_type INTO v_user_id,out_user_id,out_type
    FROM user
    WHERE (username = in_username OR e_mail = in_username) 
    AND password = in_password
    LIMIT 1;

    IF v_user_id IS NOT NULL THEN
        set v_user_exists = TRUE;
        
        INSERT INTO log (user_id, action,action_timestamp, details)
        VALUES (v_user_id, 'Login Attemp',CURRENT_TIMESTAMP, 'User successfully logged in');
        
        -- Return true for successful login
        SELECT TRUE AS result;
    ELSE
        SET v_user_exists = FALSE;
        
        INSERT INTO log (user_id, action,action_timestamp, details)
        VALUES (NULL, 'Login Attemp',CURRENT_TIMESTAMP,CONCAT('Failed login attempt for username/email: ', in_username));
        
        SELECT FALSE AS result;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `orderHistory` (IN `in_user_id` INT)   BEGIN
	SELECT CONCAT(ud.street1,',',ud.pincode,',',ud.city,',',ud.state,',',ud.country),
    uo.card_no,
    uo.tax,
    uo.shipping_price,
    uo.order_date,
    uo.quantity,
    uo.delivery_date,
    uo.total_price,
    p.name,
    p.price,
    p.color,
    p.description
    FROM user_order uo
    INNER JOIN product p ON uo.product_id = p.product_id
    INNER JOIN user_details ud ON ud.address_id = uo.delivery_address_id
    WHERE uo.delivery_date < CURRENT_DATE AND uo.buyer_id IN (SELECT buyer_id FROM buyer WHERE user_id = in_user_id);    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `purchaseInfo` (IN `p_user_id` INT, IN `p_product_id` INT, IN `p_card_no` VARCHAR(16), IN `p_delivery_address_id` INT, IN `p_tax` DECIMAL(10,2), IN `p_shipping_price` DECIMAL(10,2), IN `p_quantity` INT, IN `p_total_price` DECIMAL(10,2))   BEGIN
    DECLARE v_buyer_id INT;
    DECLARE v_is_prime BOOLEAN DEFAULT FALSE;
    DECLARE v_total_price DECIMAL(10, 2);
    DECLARE v_delivery_date DATE; 
    DECLARE v_udi INT;
    DECLARE p_order_date DATE ;
    
    SET p_order_date = CURRENT_DATE;
    
    SET v_delivery_date = DATE_ADD(p_order_date, INTERVAL 3 DAY);

    SELECT buyer_id, is_prime_user INTO v_buyer_id, v_is_prime
    FROM buyer
    WHERE user_id = p_user_id;

    IF v_buyer_id IS NULL THEN
        INSERT INTO buyer (user_id, isPrime)
        VALUES (p_user_id, FALSE);
        
        SET v_buyer_id = LAST_INSERT_ID();
    END IF;

    IF v_is_prime THEN
        SET v_total_price = p_total_price - p_shipping_price;
        SET v_delivery_date = DATE_ADD(p_order_date, INTERVAL 1 DAY);
    ELSE
        SET v_total_price = p_total_price;  
    END IF;

    INSERT INTO user_order (buyer_id, product_id, card_no, delivery_address_id, tax, shipping_price, order_date, quantity, delivery_date, total_price)
    VALUES (v_buyer_id, p_product_id, p_card_no, p_delivery_address_id, p_tax, p_shipping_price, p_order_date, p_quantity, v_delivery_date, v_total_price);
    
    SET v_udi = LAST_INSERT_ID();
    INSERT INTO log (user_id, action, details)
    VALUES (p_user_id, 'PURCHASE', CONCAT('Order detail ID: ', v_udi));

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SetUserPrime` (IN `user_id` INT)   BEGIN
    DECLARE is_prime BOOLEAN;

    -- Check if the user is already prime
    SELECT prime INTO is_prime FROM buyer WHERE id = user_id;

    -- If the user is already prime, return a message
    IF is_prime THEN
        SELECT 'You''re already prime' AS message;
    ELSE
        -- If the user is not prime, update the buyer table to set prime to true
        UPDATE buyer 
        SET prime = TRUE 
        WHERE id = user_id;

        -- Log the action
        INSERT INTO log(user_id, action, details) 
        VALUES (user_id, 'Update to Prime', 'User set to prime status');

        -- Return a success message
        SELECT 'Successfully updated to prime' AS message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateProduct` (IN `p_product_id` INT, IN `p_name` VARCHAR(255), IN `p_price` DECIMAL(10,2), IN `p_available_count` INT, IN `p_in_stock` BOOLEAN, IN `p_color` VARCHAR(50), IN `p_description` TEXT)   BEGIN
    UPDATE product
    SET name = p_name,
        price = p_price,
        available_count = p_available_count,
        in_stock = p_in_stock,
        color = p_color,
        description = p_description
    WHERE product_id = p_product_id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `buyer`
--

CREATE TABLE `buyer` (
  `buyer_id` int(11) NOT NULL,
  `is_prime_user` tinyint(1) DEFAULT 0,
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `buyer`
--

INSERT INTO `buyer` (`buyer_id`, `is_prime_user`, `user_id`) VALUES
(1, 1, 4);

-- --------------------------------------------------------

--
-- Table structure for table `category`
--

CREATE TABLE `category` (
  `category_id` int(11) NOT NULL,
  `category_name` varchar(255) NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `is_avalible` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
--
-- Indexes for table `buyer`
--
ALTER TABLE `buyer`
  ADD PRIMARY KEY (`buyer_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `category`
--
ALTER TABLE `category`
  ADD PRIMARY KEY (`category_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `log`
--
ALTER TABLE `log`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`product_id`);

--
-- Indexes for table `product_image`
--
ALTER TABLE `product_image`
  ADD PRIMARY KEY (`image_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `e_mail` (`e_mail`),
  ADD UNIQUE KEY `username_2` (`username`),
  ADD UNIQUE KEY `username_3` (`username`);

--
-- Indexes for table `user_details`
--
ALTER TABLE `user_details`
  ADD PRIMARY KEY (`address_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `user_order`
--
ALTER TABLE `user_order`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `buyer_id` (`buyer_id`,`product_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `delivery_address_id` (`delivery_address_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `buyer`
--
ALTER TABLE `buyer`
  MODIFY `buyer_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `category`
--
ALTER TABLE `category`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;

--
-- AUTO_INCREMENT for table `log`
--
ALTER TABLE `log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=180;

--
-- AUTO_INCREMENT for table `product`
--
ALTER TABLE `product`
  MODIFY `product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `product_image`
--
ALTER TABLE `product_image`
  MODIFY `image_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `user_details`
--
ALTER TABLE `user_details`
  MODIFY `address_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `user_order`
--
ALTER TABLE `user_order`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `buyer`
--
ALTER TABLE `buyer`
  ADD CONSTRAINT `buyer_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `category`
--
ALTER TABLE `category`
  ADD CONSTRAINT `category_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`);

--
-- Constraints for table `log`
--
ALTER TABLE `log`
  ADD CONSTRAINT `log_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `product_image`
--
ALTER TABLE `product_image`
  ADD CONSTRAINT `product_image_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`);

--
-- Constraints for table `user_details`
--
ALTER TABLE `user_details`
  ADD CONSTRAINT `user_details_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

--
-- Constraints for table `user_order`
--
ALTER TABLE `user_order`
  ADD CONSTRAINT `user_order_ibfk_1` FOREIGN KEY (`buyer_id`) REFERENCES `buyer` (`buyer_id`),
  ADD CONSTRAINT `user_order_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`),
  ADD CONSTRAINT `user_order_ibfk_3` FOREIGN KEY (`delivery_address_id`) REFERENCES `user_details` (`address_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
