
-- Create trigger function to generate account number
CREATE OR REPLACE FUNCTION generate_account_number()
RETURNS TRIGGER AS $$
DECLARE
    random_num BIGINT;
    account_number VARCHAR(16);
BEGIN
    -- Generate random 16-digit number
    random_num := floor(random() * (9999999999999999 - 1000000000000000 + 1) + 1000000000000000);

    WHILE EXISTS (SELECT 1 FROM account WHERE accountNumber = random_num::varchar(16)) LOOP
        -- If the account number already exists in the table, generate a new random number
        random_num := floor(random() * (9999999999999999 - 1000000000000000 + 1) + 1000000000000000);
    END LOOP;

    account_number := random_num::varchar(16);

    NEW.accountNumber := account_number;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER generate_id_trigger
BEFORE INSERT ON account
FOR EACH ROW
EXECUTE FUNCTION generate_account_number();


DEALLOCATE ALL;


CREATE EXTENSION IF NOT EXISTS pgcrypto;


CREATE OR REPLACE FUNCTION hash_password(password VARCHAR(30)) RETURNS VARCHAR(30) AS $$
BEGIN
    -- Hash the password using sha256() function and convert it to base64
    RETURN substr(encode(digest(password, 'sha256'), 'base64'), 1, 30)::VARCHAR(30);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE register(
    p_username VARCHAR(20),
    p_unhashed_password VARCHAR(30),
    p_first_name VARCHAR(20),
    p_last_name VARCHAR(20),
    p_national_id VARCHAR(10),
    p_date_of_birth DATE,
    p_type VARCHAR(10),
    p_interest_rate FLOAT
) AS $$
BEGIN
    INSERT INTO account (
        username,
        password,
        first_name,
        last_name,
        national_id,
        date_of_birth,
        type,
        interest_rate
    ) VALUES (
        p_username,
        hash_password(p_unhashed_password),
        p_first_name,
        p_last_name,
        p_national_id,
        p_date_of_birth,
        p_type,
        p_interest_rate
    );
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION insert_latest_balance() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO latest_balance (accountNumber, amount) VALUES (NEW.accountNumber, 0.0);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_account_balance
AFTER INSERT ON account
FOR EACH ROW
EXECUTE FUNCTION insert_latest_balance();


CREATE OR REPLACE PROCEDURE login(p_username VARCHAR(20), p_password VARCHAR(255))
LANGUAGE plpgsql
AS $$
DECLARE
    hashed_password VARCHAR(30);
    p_accountNumber VARCHAR(16);
BEGIN
    SELECT hash_password(p_password) INTO hashed_password;
        SELECT accountNumber FROM account WHERE username = p_username AND password = hashed_password INTO p_accountNumber;
        INSERT INTO login_log(username, login_time) VALUES (p_accountNumber, NOW());
END;
$$;


CREATE OR REPLACE PROCEDURE deposit(IN u_amount FLOAT)
LANGUAGE plpgsql
AS $$
DECLARE latest_user VARCHAR(16);
BEGIN
  -- Find the username of the user who most recently logged in based on their login time
  SELECT username INTO latest_user FROM login_log ORDER BY login_time DESC LIMIT 1;

  -- Insert a new row into transaction table with the given parameters
  INSERT INTO transaction (type, "from", "to", amount)
  VALUES ('deposit', NULL, latest_user, u_amount);
END;
$$;

CREATE OR REPLACE PROCEDURE withdraw(IN u_amount FLOAT)
LANGUAGE plpgsql
AS $$
DECLARE latest_user VARCHAR(16);
BEGIN
  -- Find the username of the user who most recently logged in based on their login time
  SELECT username INTO latest_user FROM login_log ORDER BY login_time DESC LIMIT 1;

  -- Insert a new row into transaction table with the given parameters
  INSERT INTO transaction (type, "from", "to", amount)
  VALUES ('withdraw', latest_user, NULL, u_amount);
END;
$$;

CREATE OR REPLACE PROCEDURE transfer(IN dest_accnum VARCHAR(16), IN u_amount FLOAT)
LANGUAGE plpgsql
AS $$
DECLARE
    latest_user VARCHAR(16);
BEGIN
    SELECT username INTO latest_user FROM login_log ORDER BY login_time DESC LIMIT 1;

    IF NOT EXISTS (SELECT 1 FROM account WHERE accountNumber = dest_accnum) THEN
        RAISE EXCEPTION 'Destination account number % does not exist', dest_accnum;
    END IF;

    INSERT INTO transaction (type, "from", "to", amount)
    VALUES ('transfer', latest_user, dest_accnum, u_amount);
END;
$$;


CREATE OR REPLACE PROCEDURE interest_payment() AS $$
DECLARE
  ROW RECORD; -- Declare a record variable to hold the row data
BEGIN
  -- Iterate over account table and insert corresponding rows into transaction table
  FOR ROW IN SELECT accountNumber, interest_rate FROM account LOOP
    -- Insert row into transaction table for this account with type 'interest'
    INSERT INTO transaction (type, "from", "to", amount)
    VALUES ('interest', NULL, ROW.accountNumber, ROW.interest_rate * (SELECT amount FROM latest_balance WHERE accountNumber = ROW.accountNumber));
  END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE check_balance (OUT balance FLOAT) AS $$
DECLARE
    last_user VARCHAR(16);
BEGIN
    -- Get the username of the last person to log in
    SELECT username INTO last_user FROM login_log ORDER BY login_time DESC LIMIT 1;

    -- Retrieve the latest balance for that user
    SELECT amount INTO balance FROM latest_balance WHERE accountNumber = last_user;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE update_balances() AS $$
DECLARE
    last_login_type VARCHAR(10);
    last_snapshot TIMESTAMP;
    cur_transaction transaction%ROWTYPE;
    from_balance FLOAT;
    new_balance FLOAT;
    cur_snapshot_id INTEGER;
    transaction_cursor CURSOR FOR SELECT * FROM transaction WHERE transaction_time > last_snapshot;
BEGIN
    -- Get the type of the last person to log in
    SELECT type INTO last_login_type FROM account
        WHERE accountNumber = (SELECT username FROM login_log ORDER BY login_time DESC LIMIT 1);

    -- Check if the last person to log in is an employee
    IF last_login_type <> 'employee' OR last_login_type IS NULL THEN
        RAISE EXCEPTION 'Only employees are allowed to update balances';
    END IF;

    -- If the last login was by an employee, update balances
    -- Get the timestamp of the last snapshot
    SELECT COALESCE(MAX(snapshot_timestamp), '1970-01-01 00:00:00') INTO last_snapshot FROM snapshot_log;

    -- Loop through all transactions since the last snapshot
    OPEN transaction_cursor;
    LOOP
        FETCH transaction_cursor INTO cur_transaction;
        EXIT WHEN NOT FOUND;

        -- Update balances based on transaction type
        IF cur_transaction.type = 'deposit' THEN
            UPDATE latest_balance SET amount = amount + cur_transaction.amount
                WHERE accountNumber = cur_transaction.to;
        ELSIF cur_transaction.type = 'withdraw' THEN
            SELECT amount - cur_transaction.amount INTO new_balance FROM latest_balance
                WHERE accountNumber = cur_transaction."from";
            IF new_balance >= 0 THEN
                UPDATE latest_balance SET amount = new_balance
                    WHERE accountNumber = cur_transaction."from";
            END IF;
        ELSIF cur_transaction.type = 'transfer' THEN
            SELECT amount - cur_transaction.amount INTO from_balance FROM latest_balance
                WHERE accountNumber = cur_transaction."from";
            IF from_balance >= 0 THEN
                UPDATE latest_balance SET amount = from_balance
                    WHERE accountNumber = cur_transaction."from";
                UPDATE latest_balance SET amount = amount + cur_transaction.amount
                    WHERE accountNumber = cur_transaction."to";
            END IF;
        ELSIF cur_transaction.type = 'interest' THEN
            UPDATE latest_balance SET amount = amount + cur_transaction.amount
                WHERE accountNumber = cur_transaction."to";
        END IF;
    END LOOP;

    CLOSE transaction_cursor;

    -- Insert a new snapshot log entry
    INSERT INTO snapshot_log (snapshot_timestamp) VALUES (NOW());

    -- Create a new snapshot table with the latest balances
    SELECT MAX(snapshot_ID) INTO cur_snapshot_id FROM snapshot_log;
    EXECUTE FORMAT('CREATE TABLE snapshot_%s AS SELECT * FROM latest_balance', cur_snapshot_id);

END;
$$ LANGUAGE plpgsql;
