CREATE TABLE IF NOT EXISTS tickets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    subject VARCHAR(160) NOT NULL,
    status ENUM('open','in_progress','closed') NOT NULL DEFAULT 'open',
    assigned_admin_id BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,
    last_message_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_message_by ENUM('user','admin') NOT NULL DEFAULT 'user',
    INDEX idx_tickets_status_lastmsg (status, last_message_at),
    INDEX idx_tickets_user_status (user_id, status),
    CONSTRAINT fk_tickets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_tickets_assigned_admin FOREIGN KEY (assigned_admin_id) REFERENCES admins(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ticket_messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_id BIGINT UNSIGNED NOT NULL,
    sender_type ENUM('user','admin') NOT NULL,
    sender_user_id BIGINT UNSIGNED NULL,
    sender_admin_id BIGINT UNSIGNED NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ticket_messages_ticket_time (ticket_id, created_at),
    CONSTRAINT fk_ticket_messages_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_messages_user FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_ticket_messages_admin FOREIGN KEY (sender_admin_id) REFERENCES admins(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_ticket_messages_validate_insert;
DROP TRIGGER IF EXISTS trg_ticket_messages_validate_update;

DELIMITER $$
CREATE TRIGGER trg_ticket_messages_validate_insert
BEFORE INSERT ON ticket_messages
FOR EACH ROW
BEGIN
    IF NOT (
        (NEW.sender_type = 'user' AND NEW.sender_user_id IS NOT NULL AND NEW.sender_admin_id IS NULL)
        OR
        (NEW.sender_type = 'admin' AND NEW.sender_admin_id IS NOT NULL AND NEW.sender_user_id IS NULL)
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid ticket message sender mapping.';
    END IF;
END$$

CREATE TRIGGER trg_ticket_messages_validate_update
BEFORE UPDATE ON ticket_messages
FOR EACH ROW
BEGIN
    IF NOT (
        (NEW.sender_type = 'user' AND NEW.sender_user_id IS NOT NULL AND NEW.sender_admin_id IS NULL)
        OR
        (NEW.sender_type = 'admin' AND NEW.sender_admin_id IS NOT NULL AND NEW.sender_user_id IS NULL)
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid ticket message sender mapping.';
    END IF;
END$$
DELIMITER ;
