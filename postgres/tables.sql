CREATE TABLE account (
    username VARCHAR(20) UNIQUE,
    accountNumber VARCHAR(16),
    password VARCHAR(30),
    first_name VARCHAR(20),
    last_name VARCHAR(20),
    national_id VARCHAR(10),
    date_of_birth DATE,
    type VARCHAR(10),
    interest_rate FLOAT,
    PRIMARY KEY(accountNumber),
    CHECK(type IN ('client', 'employee')),
    CHECK (date_of_birth <= (CURRENT_DATE - INTERVAL '13 years'))
);


CREATE TABLE login_log (
    username VARCHAR(16),
    login_time TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY(username, login_time),
    FOREIGN KEY(username) references account
);


CREATE TABLE transaction (
    type VARCHAR(10),
    transaction_time TIMESTAMP DEFAULT NOW(),
    "from" VARCHAR(16),
    "to" VARCHAR(16),
    amount FLOAT,
    FOREIGN KEY("from") REFERENCES account(accountNumber),
    FOREIGN KEY("to") REFERENCES account(accountNumber),
    CHECK (type in ('deposit', 'withdraw', 'transfer', 'interest'))
);

CREATE TABLE latest_balance (
    accountNumber VARCHAR(16),
    amount FLOAT,
    FOREIGN KEY (accountNumber) REFERENCES account(accountNumber)
);

CREATE TABLE snapshot_log (
    snapshot_ID SERIAL,
    snapshot_timestamp TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY(snapshot_ID)
);