DROP TABLE IF EXISTS AUDIT;
CREATE TABLE AUDIT (
	AUDIT_ID SERIAL,
	USER_ID INTEGER,
	USER_FULLNAME TEXT,
	AUDIT_DATE timestamptz,
	PAGE TEXT,
	ACTION TEXT,
	PARAMETERS TEXT,
	SUCCESS character(1) NOT NULL,
	AUDIT_ACTION_TYPE TEXT,
    PRIMARY KEY  (AUDIT_ID)
);
CREATE INDEX IDX_AUDIT_DATE ON audit(AUDIT_DATE);
CREATE INDEX IDX_AUDIT_USER ON audit(USER_FULLNAME);
CREATE INDEX IDX_AUDIT_ACTION_TYPE ON audit(AUDIT_ACTION_TYPE);
--
-- Table structure for table CONFIGURATION
--

DROP TABLE IF EXISTS CONFIGURATION;
CREATE TABLE CONFIGURATION (
  config_key TEXT NOT NULL,
  config_value TEXT,
  PRIMARY KEY  (config_key)
);

--
-- Dumping data for table CONFIGURATION
--

INSERT INTO CONFIGURATION VALUES
('initialized','false'), ('completeDayHours','8'),
('showTurnOver','true'), ('localeLanguage','en'), ('currency','en-US'),
('localeCountry','en-US'), ('availableTranslations','en,nl,fr,it'),
('mailFrom','noreply@localhost.net'), ('smtpPort','25'),
('mailSmtp','127.0.0.1'), ('demoMode','false'), ('version', '1.4.2');
INSERT INTO CONFIGURATION (CONFIG_KEY, CONFIG_VALUE) VALUES('reminderEnabled', 'false');
INSERT INTO CONFIGURATION (CONFIG_KEY, CONFIG_VALUE) VALUES('reminderBody', 'Hello $name,\r\n\r\nThis is an automated message.\r\n\r\nOur records show that you have not posted your weekly hours online. Please be sure to post your hours by 5:30PM Friday.\r\n\r\nThank You,\r\n\r\neHour');
INSERT INTO CONFIGURATION (CONFIG_KEY, CONFIG_VALUE) VALUES('reminderTime', '0 30 17 * * FRI');
INSERT INTO CONFIGURATION (CONFIG_KEY, CONFIG_VALUE) VALUES('reminderSubject', 'Missing hours');
INSERT INTO CONFIGURATION (CONFIG_KEY, CONFIG_VALUE) VALUES('reminderMinimalHours', '32');

--
-- Table structure for table CUSTOMER
--

DROP TABLE IF EXISTS CUSTOMER CASCADE;
CREATE TABLE CUSTOMER (
  CUSTOMER_ID SERIAL,
  NAME TEXT NOT NULL,
  DESCRIPTION TEXT,
  CODE TEXT NOT NULL,
  ACTIVE character(1) NOT NULL default true,
  PRIMARY KEY  (CUSTOMER_ID),
  UNIQUE (NAME,CODE)
);

--
-- Table structure for table USER_DEPARTMENT
--

DROP TABLE IF EXISTS USER_DEPARTMENT CASCADE;
CREATE TABLE USER_DEPARTMENT (
  DEPARTMENT_ID SERIAL,
  NAME TEXT NOT NULL,
  CODE TEXT NOT NULL,
  PRIMARY KEY  (DEPARTMENT_ID)
);


--
-- Dumping data for table USER_DEPARTMENT
--

INSERT INTO USER_DEPARTMENT (DEPARTMENT_ID, NAME, CODE) VALUES (1,'Internal','INT');

--
-- Table structure for table "users"
--

DROP TABLE IF EXISTS USERS CASCADE;
CREATE TABLE USERS (
  USER_ID SERIAL,
  USERNAME TEXT NOT NULL,
  PASSWORD TEXT NOT NULL,
  FIRST_NAME TEXT,
  LAST_NAME TEXT NOT NULL,
  DEPARTMENT_ID INTEGER,
  EMAIL TEXT,
  SALT INTEGER,
  ACTIVE character(1) default 'Y',
  PRIMARY KEY  (USER_ID),
  UNIQUE (USERNAME),
  UNIQUE (USERNAME,ACTIVE),
  CONSTRAINT USER_fk FOREIGN KEY (DEPARTMENT_ID) REFERENCES USER_DEPARTMENT (DEPARTMENT_ID)
);
CREATE INDEX IDX_USERNAME_PASSWORD ON "users" (USERNAME,PASSWORD);
CREATE INDEX ORGANISATION_ID ON "users" (DEPARTMENT_ID);

--
-- Dumping data for table users
--

INSERT INTO "users" (USER_ID, USERNAME, PASSWORD, FIRST_NAME, LAST_NAME, EMAIL, ACTIVE) VALUES (1,'admin','','eHour','Admin','','Y');

DROP TABLE IF EXISTS USER_TO_DEPARTMENT CASCADE;
CREATE TABLE USER_TO_DEPARTMENT (
  DEPARTMENT_ID INTEGER NOT NULL,
  USER_ID       INTEGER NOT NULL,
  PRIMARY KEY (DEPARTMENT_ID, USER_ID),
  CONSTRAINT FK_USER_TO_USER FOREIGN KEY (USER_ID) REFERENCES USERS (USER_ID),
  CONSTRAINT FK_USER_TO_DEPT FOREIGN KEY (DEPARTMENT_ID) REFERENCES USER_DEPARTMENT (DEPARTMENT_ID)
);


ALTER TABLE USER_DEPARTMENT ADD COLUMN MANAGER_USER_ID INTEGER DEFAULT NULL;
ALTER TABLE USER_DEPARTMENT ADD COLUMN TIMEZONE VARCHAR(128) DEFAULT NULL;
ALTER TABLE USER_DEPARTMENT ADD COLUMN PARENT_DEPARTMENT_ID INTEGER DEFAULT NULL;

INSERT INTO USER_TO_DEPARTMENT VALUES (1, 1);

--
-- Table structure for table MAIL_LOG
--

DROP TABLE IF EXISTS MAIL_LOG;
CREATE TABLE MAIL_LOG (
  MAIL_LOG_ID SERIAL,
  TIMESTAMP timestamptz NOT NULL,
  SUCCESS character(1),
  MAIL_EVENT VARCHAR(64),
  MAIL_TO VARCHAR(255),
  PRIMARY KEY  (MAIL_LOG_ID)
);
CREATE INDEX IDX_MAIL ON mail_log (MAIL_EVENT, MAIL_TO);

--
-- Table structure for table PROJECT
--

DROP TABLE IF EXISTS PROJECT CASCADE;
CREATE TABLE PROJECT (
  PROJECT_ID SERIAL,
  CUSTOMER_ID INTEGER,
  NAME TEXT NOT NULL,
  DESCRIPTION TEXT,
  CONTACT TEXT,
  PROJECT_CODE TEXT NOT NULL,
  DEFAULT_PROJECT character(1) default 'N',
  ACTIVE character(1) default 'Y',
  BILLABLE character(1) default 'Y',  
  PROJECT_MANAGER INTEGER,
  PRIMARY KEY  (PROJECT_ID),
  CONSTRAINT PROJECT_fk FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMER (CUSTOMER_ID),
  CONSTRAINT PROJECT_fk1 FOREIGN KEY (PROJECT_MANAGER) REFERENCES "users" (USER_ID)
);
CREATE INDEX CUSTOMER_ID ON project (CUSTOMER_ID);
CREATE INDEX PROJECT_fk1 ON project (PROJECT_MANAGER);

--
-- Table structure for table PROJECT_ASSIGNMENT_TYPE
--

DROP TABLE IF EXISTS PROJECT_ASSIGNMENT_TYPE CASCADE;
CREATE TABLE PROJECT_ASSIGNMENT_TYPE (
  ASSIGNMENT_TYPE_ID INTEGER NOT NULL,
  ASSIGNMENT_TYPE TEXT,
  PRIMARY KEY  (ASSIGNMENT_TYPE_ID)
);

--
-- Table structure for table PROJECT_ASSIGNMENT
--

DROP TABLE IF EXISTS PROJECT_ASSIGNMENT CASCADE;
CREATE TABLE PROJECT_ASSIGNMENT (
  ASSIGNMENT_ID INTEGER NOT NULL,
  PROJECT_ID INTEGER NOT NULL,
  HOURLY_RATE real,
  DATE_START TIMESTAMP,
  DATE_END TIMESTAMP,
  ROLE TEXT,
  USER_ID INTEGER NOT NULL,
  ACTIVE character(1) NOT NULL default 'Y',
  ASSIGNMENT_TYPE_ID INTEGER NOT NULL,
  ALLOTTED_HOURS real,
  ALLOTTED_HOURS_OVERRUN real,
  NOTIFY_PM_ON_OVERRUN character(1) default 'N',
  PRIMARY KEY  (ASSIGNMENT_ID),
  CONSTRAINT PROJECT_ASSIGNMENT_fk2 FOREIGN KEY (ASSIGNMENT_TYPE_ID) REFERENCES PROJECT_ASSIGNMENT_TYPE (ASSIGNMENT_TYPE_ID),
  CONSTRAINT PROJECT_ASSIGNMENT_fk FOREIGN KEY (PROJECT_ID) REFERENCES PROJECT (PROJECT_ID),
  CONSTRAINT PROJECT_ASSIGNMENT_fk1 FOREIGN KEY (USER_ID) REFERENCES USERS (USER_ID)
);
CREATE INDEX PROJECT_ID ON project_assignment (PROJECT_ID);
CREATE INDEX USER_ID ON project_assignment (USER_ID);
CREATE INDEX ASSIGNMENT_TYPE_ID ON project_assignment (ASSIGNMENT_TYPE_ID);

--
-- Dumping data for table PROJECT_ASSIGNMENT_TYPE
--

INSERT INTO PROJECT_ASSIGNMENT_TYPE VALUES (0,'DATE_TYPE'),(2,'TIME_ALLOTTED_FIXED'),(3,'TIME_ALLOTTED_FLEX');

--
-- Table structure for table TIMESHEET_COMMENT
--

DROP TABLE IF EXISTS TIMESHEET_COMMENT;
CREATE TABLE TIMESHEET_COMMENT (
  USER_ID INTEGER NOT NULL,
  COMMENT_DATE TIMESTAMP NOT NULL,
  COMMENT TEXT,
  PRIMARY KEY  (COMMENT_DATE,USER_ID)
);

--
-- Table structure for table TIMESHEET_ENTRY
--

DROP TABLE IF EXISTS TIMESHEET_ENTRY;
CREATE TABLE TIMESHEET_ENTRY (
  ASSIGNMENT_ID INTEGER NOT NULL,
  ENTRY_DATE TIMESTAMP NOT NULL,
  UPDATE_DATE TIMESTAMP,  
  HOURS real,
  COMMENT TEXT,
  PRIMARY KEY  (ENTRY_DATE,ASSIGNMENT_ID),
  CONSTRAINT TIMESHEET_ENTRY_fk FOREIGN KEY (ASSIGNMENT_ID) REFERENCES PROJECT_ASSIGNMENT (ASSIGNMENT_ID)
);
CREATE INDEX ASSIGNMENT_ID ON timesheet_entry (ASSIGNMENT_ID);

--
-- Table structure for table USER_ROLE
--

DROP TABLE IF EXISTS USER_ROLE CASCADE;
CREATE TABLE USER_ROLE (
  ROLE TEXT NOT NULL,
  NAME TEXT NOT NULL,
  PRIMARY KEY  (ROLE)
);


--
-- Dumping data for table USER_ROLE
--

INSERT INTO USER_ROLE VALUES ('ROLE_ADMIN','Administrator'),('ROLE_CONSULTANT','Consultant'),('ROLE_PROJECTMANAGER','PM'),('ROLE_REPORT','Report role'),('ROLE_MANAGER','Manager');

--
-- Table structure for table USER_TO_USERROLE
--

DROP TABLE IF EXISTS USER_TO_USERROLE CASCADE;
CREATE TABLE USER_TO_USERROLE (
  ROLE TEXT NOT NULL,
  USER_ID INTEGER NOT NULL,
  PRIMARY KEY  (ROLE,USER_ID),
  CONSTRAINT USER_TO_USERROLE_fk FOREIGN KEY (ROLE) REFERENCES USER_ROLE (ROLE),
  CONSTRAINT USER_TO_USERROLE_fk1 FOREIGN KEY (USER_ID) REFERENCES "users" (USER_ID)
);
CREATE INDEX USER_TO_USERROLE_ROLE ON user_to_userrole (ROLE);
CREATE INDEX USER_TO_USERROLE_USER_ID ON user_to_userrole (USER_ID);

--
-- Dumping data for table USER_TO_USERROLE
--

INSERT INTO USER_TO_USERROLE (ROLE, USER_ID) VALUES ('ROLE_ADMIN',1),('ROLE_REPORT',1);

DROP TABLE IF EXISTS CONFIGURATION_BIN CASCADE;
CREATE TABLE CONFIGURATION_BIN (
  CONFIG_KEY TEXT NOT NULL,
  CONFIG_VALUE oid,
  METADATA TEXT,
  PRIMARY KEY  (config_key)
);

DROP SEQUENCE IF EXISTS hibernate_sequence CASCADE;
CREATE SEQUENCE hibernate_sequence START 1;

DROP TABLE IF EXISTS TIMESHEET_LOCK CASCADE;
CREATE  TABLE TIMESHEET_LOCK (
  LOCK_ID INTEGER NOT NULL,
  DATE_START TIMESTAMP NOT NULL ,
  DATE_END TIMESTAMP NOT NULL ,
  NAME VARCHAR(255) NULL ,
  PRIMARY KEY (LOCK_ID) );

CREATE INDEX TIMESHEET_LOCK_IDX ON TIMESHEET_LOCK (DATE_START, DATE_END);

DROP TABLE IF EXISTS TIMESHEET_LOCK_EXCLUSION CASCADE;
CREATE TABLE TIMESHEET_LOCK_EXCLUSION (
  LOCK_ID INTEGER,
  USER_ID INTEGER,
  PRIMARY KEY (LOCK_ID, USER_ID),
  CONSTRAINT FK_EXCL_USER_ID FOREIGN KEY (USER_ID) REFERENCES USERS (USER_ID) ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT FK_EXCL_LOCK_ID FOREIGN KEY (LOCK_ID) REFERENCES TIMESHEET_LOCK (LOCK_ID) ON UPDATE NO ACTION ON DELETE NO ACTION
);



