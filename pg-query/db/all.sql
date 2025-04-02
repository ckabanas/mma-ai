-- Create database owner/role
CREATE ROLE rentalco WITH LOGIN PASSWORD 'rentalco';

-- Create the database with the owner
CREATE DATABASE rentalco WITH OWNER = rentalco;

-- Connect to the new database
\c rentalco

-- Set default privileges for the owner
ALTER DEFAULT PRIVILEGES FOR ROLE rentalco IN SCHEMA public
GRANT ALL ON TABLES TO rentalco;

ALTER DEFAULT PRIVILEGES FOR ROLE rentalco IN SCHEMA public
GRANT ALL ON SEQUENCES TO rentalco;

-- 1. Customers Table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    credit_limit DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Equipment Categories Table
CREATE TABLE equipment_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    daily_insurance_rate DECIMAL(10, 2) NOT NULL
);

-- 3. Inventory Locations Table (moved up in creation order)
CREATE TABLE inventory_locations (
    location_id SERIAL PRIMARY KEY,
    location_name VARCHAR(100) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE
);

-- 4. Employees Table (modified)
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    hire_date DATE NOT NULL,
    primary_location_id INTEGER REFERENCES inventory_locations(location_id),
    certification TEXT[],
    is_active BOOLEAN DEFAULT TRUE
);

-- 5. Employee-Location Assignment Table (new junction table)
CREATE TABLE employee_locations (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    location_id INTEGER REFERENCES inventory_locations(location_id),
    is_primary BOOLEAN DEFAULT FALSE,
    start_date DATE NOT NULL,
    end_date DATE,
    assignment_type VARCHAR(50) CHECK (assignment_type IN ('Permanent', 'Temporary', 'Rotating')),
    UNIQUE(employee_id, location_id, start_date)
);

-- 6. Update Inventory Locations Table with manager reference
ALTER TABLE inventory_locations ADD COLUMN manager_id INTEGER REFERENCES employees(employee_id);

-- 7. Equipment Table
CREATE TABLE equipment (
    equipment_id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES equipment_categories(category_id),
    equipment_name VARCHAR(100) NOT NULL,
    model_number VARCHAR(50) NOT NULL,
    manufacturer VARCHAR(100) NOT NULL,
    purchase_date DATE NOT NULL,
    purchase_price DECIMAL(10, 2) NOT NULL,
    current_value DECIMAL(10, 2) NOT NULL,
    daily_rental_rate DECIMAL(10, 2) NOT NULL,
    weekly_rental_rate DECIMAL(10, 2) NOT NULL,
    monthly_rental_rate DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) CHECK (status IN ('Available', 'Rented', 'Maintenance', 'Retired')),
    maintenance_interval INTEGER NOT NULL, -- Days between scheduled maintenance
    last_maintenance_date DATE,
    hours_used INTEGER DEFAULT 0,
    condition_rating INTEGER CHECK (condition_rating BETWEEN 1 AND 5),
    location_id INTEGER REFERENCES inventory_locations(location_id),
    notes TEXT
);

-- 8. Rentals Table
CREATE TABLE rentals (
    rental_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    rental_date DATE NOT NULL,
    expected_return_date DATE NOT NULL,
    actual_return_date DATE,
    total_amount DECIMAL(10, 2),
    deposit_amount DECIMAL(10, 2),
    deposit_returned BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) CHECK (status IN ('Reserved', 'Active', 'Completed', 'Cancelled')),
    created_by INTEGER REFERENCES employees(employee_id),
    pickup_location_id INTEGER REFERENCES inventory_locations(location_id),
    return_location_id INTEGER REFERENCES inventory_locations(location_id),
    insurance_coverage BOOLEAN DEFAULT TRUE,
    po_number VARCHAR(50),
    notes TEXT
);

-- 9. Rental Items (Junction Table)
CREATE TABLE rental_items (
    rental_item_id SERIAL PRIMARY KEY,
    rental_id INTEGER REFERENCES rentals(rental_id),
    equipment_id INTEGER REFERENCES equipment(equipment_id),
    hourly_usage INTEGER,
    daily_rate DECIMAL(10, 2) NOT NULL,
    quantity INTEGER DEFAULT 1,
    start_condition TEXT,
    end_condition TEXT,
    damages_reported BOOLEAN DEFAULT FALSE,
    damage_description TEXT,
    damage_charges DECIMAL(10, 2) DEFAULT 0.00
);

-- 10. Maintenance Records Table
CREATE TABLE maintenance_records (
    maintenance_id SERIAL PRIMARY KEY,
    equipment_id INTEGER REFERENCES equipment(equipment_id),
    maintenance_date DATE NOT NULL,
    maintenance_type VARCHAR(50) CHECK (maintenance_type IN ('Scheduled', 'Repair', 'Inspection', 'Emergency')),
    description TEXT NOT NULL,
    cost DECIMAL(10, 2) NOT NULL,
    performed_by INTEGER REFERENCES employees(employee_id),
    hours_added INTEGER,
    parts_replaced TEXT,
    next_maintenance_date DATE,
    status VARCHAR(20) CHECK (status IN ('Scheduled', 'In Progress', 'Completed', 'Postponed')),
    notes TEXT
);

-- 11. Payments Table
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    rental_id INTEGER REFERENCES rentals(rental_id),
    payment_date DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_reference VARCHAR(100),
    processed_by INTEGER REFERENCES employees(employee_id),
    is_refund BOOLEAN DEFAULT FALSE,
    notes TEXT
);

-- 12. Equipment Attachments Table
CREATE TABLE equipment_attachments (
    attachment_id SERIAL PRIMARY KEY,
    equipment_id INTEGER REFERENCES equipment(equipment_id),
    attachment_name VARCHAR(100) NOT NULL,
    attachment_type VARCHAR(50) NOT NULL,
    daily_rate DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) CHECK (status IN ('Available', 'Rented', 'Maintenance', 'Retired')),
    location_id INTEGER REFERENCES inventory_locations(location_id),
    notes TEXT
);

-- Insert data into customers table
INSERT INTO customers (company_name, contact_person, email, phone, address, city, state, postal_code, credit_limit, is_active, created_at)
VALUES
    -- Seattle Customers (30 customers for largest location)
    ('Pacific Northwest Construction', 'Eleanor Hughes', 'ehughes@pnwconstruction.com', '206-555-4301', '1220 Westlake Ave N', 'Seattle', 'Washington', '98109', 50000.00, TRUE, '2020-03-15'),
    ('Emerald City Builders', 'Marcus Reeves', 'mreeves@emeraldbuilders.com', '206-555-4302', '512 Yale Ave N', 'Seattle', 'Washington', '98109', 75000.00, TRUE, '2019-06-22'),
    ('Rainier Development Group', 'Sophia Chen', 'schen@rainierdevelopment.com', '206-555-4303', '3401 Thorndyke Ave W', 'Seattle', 'Washington', '98119', 100000.00, TRUE, '2018-11-10'),
    ('Sound Excavation Services', 'Brandon Mills', 'bmills@soundexcavation.com', '206-555-4304', '7600 Sandpoint Way NE', 'Seattle', 'Washington', '98115', 35000.00, TRUE, '2021-02-18'),
    ('Cascade Infrastructure LLC', 'Olivia Washington', 'owashington@cascadeinfra.com', '206-555-4305', '2501 Elliott Ave', 'Seattle', 'Washington', '98121', 150000.00, TRUE, '2019-09-05'),
    ('Olympic Contracting', 'Daniel Freeman', 'dfreeman@olympiccontracting.com', '206-555-4306', '1000 Mercer St', 'Seattle', 'Washington', '98109', 85000.00, TRUE, '2020-05-12'),
    ('Evergreen Builders Supply', 'Isabella Rodriguez', 'irodriguez@evergreensupply.com', '206-555-4307', '4455 E Marginal Way S', 'Seattle', 'Washington', '98134', 45000.00, TRUE, '2022-01-20'),
    ('Puget Sound Contractors', 'Thomas Morgan', 'tmorgan@pugetsoundcontractors.com', '206-555-4308', '1545 NW Market St', 'Seattle', 'Washington', '98107', 70000.00, TRUE, '2019-08-17'),
    ('Northwest Demolition Co.', 'Rebecca Foster', 'rfoster@nwdemolition.com', '206-555-4309', '2700 16th Ave SW', 'Seattle', 'Washington', '98126', 55000.00, TRUE, '2021-04-25'),
    ('Seattle Municipal Projects', 'James Wilson', 'jwilson@seattlemunicipal.gov', '206-555-4310', '700 5th Ave', 'Seattle', 'Washington', '98104', 500000.00, TRUE, '2017-10-30'),
    ('Pioneer Construction Management', 'Alexis Turner', 'aturner@pioneercm.com', '206-555-4311', '3600 15th Ave W', 'Seattle', 'Washington', '98119', 120000.00, TRUE, '2019-11-15'),
    ('Ballard Marine Construction', 'Noah Sullivan', 'nsullivan@ballardmarine.com', '206-555-4312', '8900 24th Ave NW', 'Seattle', 'Washington', '98117', 80000.00, TRUE, '2020-07-08'),
    ('First Ave Development', 'Emma Taylor', 'etaylor@firstavedevelopment.com', '206-555-4313', '2200 1st Ave S', 'Seattle', 'Washington', '98134', 95000.00, TRUE, '2018-12-18'),
    ('Harbor Island Shipyards', 'Lucas Harris', 'lharris@harborisland.com', '206-555-4314', '2801 Alaskan Way', 'Seattle', 'Washington', '98121', 200000.00, TRUE, '2019-04-10'),
    ('Green Lake Landscaping', 'Sophia Walker', 'swalker@greenlakeland.com', '206-555-4315', '7201 E Green Lake Dr N', 'Seattle', 'Washington', '98115', 25000.00, TRUE, '2021-03-05'),
    ('Capitol Hill Renovation Experts', 'Gabriel Martinez', 'gmartinez@capitolrenovation.com', '206-555-4316', '619 E Pine St', 'Seattle', 'Washington', '98122', 40000.00, TRUE, '2022-02-10'),
    ('Lake Union Drydock Company', 'Ava Richardson', 'arichardson@lakeuniondrydock.com', '206-555-4317', '1515 Fairview Ave E', 'Seattle', 'Washington', '98102', 180000.00, TRUE, '2019-07-25'),
    ('Belltown General Contractors', 'William Parker', 'wparker@belltowngc.com', '206-555-4318', '2821 2nd Ave', 'Seattle', 'Washington', '98121', 65000.00, TRUE, '2020-10-15'),
    ('SODO Industrial Construction', 'Charlotte Moore', 'cmoore@sodoindustrial.com', '206-555-4319', '3800 1st Ave S', 'Seattle', 'Washington', '98134', 110000.00, TRUE, '2018-09-22'),
    ('University District Home Builders', 'Jackson Cooper', 'jcooper@udhomebuilders.com', '206-555-4320', '4500 9th Ave NE', 'Seattle', 'Washington', '98105', 35000.00, TRUE, '2021-05-11'),
    ('Duwamish Heavy Industries', 'Victoria Bryant', 'vbryant@duwamishheavy.com', '206-555-4321', '7051 E Marginal Way S', 'Seattle', 'Washington', '98108', 275000.00, TRUE, '2017-08-10'),
    ('Fremont Bridge Construction', 'Samuel Lewis', 'slewis@fremontbridge.com', '206-555-4322', '3601 Fremont Ave N', 'Seattle', 'Washington', '98103', 50000.00, TRUE, '2021-01-28'),
    ('Pike Place Renovations', 'Abigail White', 'awhite@pikeplacerenovations.com', '206-555-4323', '1901 Western Ave', 'Seattle', 'Washington', '98101', 30000.00, TRUE, '2022-03-15'),
    ('West Seattle Excavation', 'Elijah Thompson', 'ethompson@westseattleexcavation.com', '206-555-4324', '4517 California Ave SW', 'Seattle', 'Washington', '98116', 45000.00, TRUE, '2020-04-10'),
    ('Seattle Port Authority', 'Grace Nelson', 'gnelson@seattleport.gov', '206-555-4325', '2711 Alaskan Way', 'Seattle', 'Washington', '98121', 350000.00, TRUE, '2016-05-20'),
    ('Rainier Valley Property Developers', 'Henry Mitchell', 'hmitchell@rainiervalleydev.com', '206-555-4326', '3815 S Othello St', 'Seattle', 'Washington', '98118', 70000.00, TRUE, '2019-12-05'),
    ('Magnolia Residential Contractors', 'Zoey Anderson', 'zanderson@magnoliaresidential.com', '206-555-4327', '3214 W McGraw St', 'Seattle', 'Washington', '98199', 55000.00, TRUE, '2020-08-22'),
    ('Elliott Bay Marina Services', 'Benjamin Clark', 'bclark@elliottbaymarina.com', '206-555-4328', '2601 W Marina Pl', 'Seattle', 'Washington', '98199', 120000.00, TRUE, '2019-05-18'),
    ('Downtown Seattle Association', 'Penelope Wright', 'pwright@downtownseattle.org', '206-555-4329', '1809 7th Ave', 'Seattle', 'Washington', '98101', 90000.00, TRUE, '2018-10-12'),
    ('Beacon Hill Community Development', 'Nathan King', 'nking@beaconhilldev.com', '206-555-4330', '2821 15th Ave S', 'Seattle', 'Washington', '98144', 40000.00, TRUE, '2021-06-30'),
    
    -- Houston Customers (28 customers)
    ('Gulf Coast Development', 'Julia Ramirez', 'jramirez@gulfcoastdev.com', '713-555-5301', '1200 Smith St', 'Houston', 'Texas', '77002', 150000.00, TRUE, '2018-07-15'),
    ('Texas Oil Field Services', 'Robert Johnson', 'rjohnson@texasoilfield.com', '713-555-5302', '3200 Kirby Dr', 'Houston', 'Texas', '77098', 300000.00, TRUE, '2019-03-22'),
    ('Bayou City Contractors', 'Melissa Williams', 'mwilliams@bayoucity.com', '713-555-5303', '4400 Post Oak Pkwy', 'Houston', 'Texas', '77027', 125000.00, TRUE, '2020-01-10'),
    ('Houston Harbor Construction', 'Anthony Davis', 'adavis@houstonharbor.com', '713-555-5304', '8500 Clinton Dr', 'Houston', 'Texas', '77029', 200000.00, TRUE, '2019-05-15'),
    ('Energy Corridor Builders', 'Samantha Brown', 'sbrown@energybuilders.com', '713-555-5305', '14701 St Mary''s Ln', 'Houston', 'Texas', '77079', 175000.00, TRUE, '2018-11-08'),
    ('Space City Development', 'Daniel Rodriguez', 'drodriguez@spacecitydev.com', '713-555-5306', '2929 Buffalo Speedway', 'Houston', 'Texas', '77019', 220000.00, TRUE, '2020-04-22'),
    ('Greater Houston Excavation', 'Rachel Martinez', 'rmartinez@houstonexcavation.com', '713-555-5307', '5757 Westheimer Rd', 'Houston', 'Texas', '77057', 85000.00, TRUE, '2021-02-18'),
    ('Lone Star Industrial Services', 'Joshua Smith', 'jsmith@lonestarindustrial.com', '713-555-5308', '10000 Northwest Fwy', 'Houston', 'Texas', '77092', 250000.00, TRUE, '2019-09-05'),
    ('Memorial Area Home Builders', 'Elizabeth Thompson', 'ethompson@memorialbuilders.com', '713-555-5309', '8505 Memorial Dr', 'Houston', 'Texas', '77024', 60000.00, TRUE, '2020-06-12'),
    ('Harris County Infrastructure', 'Christopher Wilson', 'cwilson@harriscounty.gov', '713-555-5310', '1001 Preston St', 'Houston', 'Texas', '77002', 500000.00, TRUE, '2017-10-30'),
    ('Port of Houston Authority', 'Madison Lee', 'mlee@porthouston.gov', '713-555-5311', '111 East Loop North', 'Houston', 'Texas', '77029', 450000.00, TRUE, '2018-08-17'),
    ('Galveston Bay Construction', 'Tyler Anderson', 'tanderson@galvestonbay.com', '713-555-5312', '7400 Gulf Fwy', 'Houston', 'Texas', '77017', 180000.00, TRUE, '2019-11-24'),
    ('Houston Medical Center Development', 'Emily Clark', 'eclark@medcenterdev.com', '713-555-5313', '6624 Fannin St', 'Houston', 'Texas', '77030', 230000.00, TRUE, '2020-03-15'),
    ('Downtown Houston Redevelopment', 'Nicholas Garcia', 'ngarcia@downtownhouston.org', '713-555-5314', '909 Fannin St', 'Houston', 'Texas', '77010', 275000.00, TRUE, '2019-07-22'),
    ('Katy Freeway Contractors', 'Olivia Hernandez', 'ohernandez@katyfreeway.com', '713-555-5315', '9800 Katy Fwy', 'Houston', 'Texas', '77055', 130000.00, TRUE, '2021-01-08'),
    ('Heights Renovation Specialists', 'Ethan Lewis', 'elewis@heightsrenovation.com', '713-555-5316', '725 Yale St', 'Houston', 'Texas', '77007', 50000.00, TRUE, '2022-02-10'),
    ('Midtown Urban Development', 'Sophia Nguyen', 'snguyen@midtowndev.com', '713-555-5317', '2800 Main St', 'Houston', 'Texas', '77002', 95000.00, TRUE, '2020-08-25'),
    ('Ship Channel Construction Inc.', 'Ryan Mitchell', 'rmitchell@shipchannelconst.com', '713-555-5318', '3900 Navigation Blvd', 'Houston', 'Texas', '77003', 240000.00, TRUE, '2019-04-18'),
    ('Westchase District Builders', 'Hannah Rodriguez', 'hrodriguez@westchasebuilders.com', '713-555-5319', '10375 Richmond Ave', 'Houston', 'Texas', '77042', 110000.00, TRUE, '2020-10-15'),
    ('Pasadena Industrial Contractors', 'Jason Taylor', 'jtaylor@pasadenaindustrial.com', '713-555-5320', '5100 Pasadena Blvd', 'Pasadena', 'Texas', '77505', 190000.00, TRUE, '2018-09-28'),
    ('Pearland Development Group', 'Sarah White', 'swhite@pearlanddev.com', '713-555-5321', '2500 Broadway St', 'Pearland', 'Texas', '77581', 75000.00, TRUE, '2021-03-11'),
    ('Clear Lake Construction', 'David Johnson', 'djohnson@clearlakeconst.com', '713-555-5322', '1600 NASA Pkwy', 'Houston', 'Texas', '77058', 120000.00, TRUE, '2020-07-14'),
    ('Spring Branch Excavation', 'Natalie Moore', 'nmoore@springbranchexcavation.com', '713-555-5323', '8800 Kempwood Dr', 'Houston', 'Texas', '77080', 65000.00, TRUE, '2021-05-28'),
    ('Houston Airports Development', 'Alexander Brown', 'abrown@houstonairports.gov', '713-555-5324', '16930 JFK Blvd', 'Houston', 'Texas', '77032', 350000.00, TRUE, '2018-06-20'),
    ('Baytown Industrial Services', 'Grace Thomas', 'gthomas@baytownindustrial.com', '713-555-5325', '5700 Bayway Dr', 'Baytown', 'Texas', '77520', 210000.00, TRUE, '2019-12-05'),
    ('Sugar Land Builders', 'William Martin', 'wmartin@sugarlandbuilders.com', '713-555-5326', '16100 Southwest Fwy', 'Sugar Land', 'Texas', '77479', 90000.00, TRUE, '2020-09-22'),
    ('Channelview Construction', 'Isabella Wright', 'iwright@channelviewconst.com', '713-555-5327', '15800 East Fwy', 'Channelview', 'Texas', '77530', 135000.00, TRUE, '2019-10-18'),
    ('The Woodlands Development Corp', 'Joseph Miller', 'jmiller@woodlandsdev.com', '713-555-5328', '9950 Woodlands Pkwy', 'The Woodlands', 'Texas', '77381', 225000.00, TRUE, '2018-11-12'),
    
    -- Chicago Customers (25 customers)
    ('Windy City Developers', 'Michael Stewart', 'mstewart@windycitydev.com', '312-555-6301', '200 E Randolph St', 'Chicago', 'Illinois', '60601', 180000.00, TRUE, '2019-03-12'),
    ('Lake Michigan Construction', 'Jennifer Adams', 'jadams@lakemichiganconstruction.com', '312-555-6302', '505 N Lake Shore Dr', 'Chicago', 'Illinois', '60611', 200000.00, TRUE, '2018-08-24'),
    ('Chicago River Builders', 'Andrew Wilson', 'awilson@chicagoriverbuilders.com', '312-555-6303', '333 N Canal St', 'Chicago', 'Illinois', '60606', 155000.00, TRUE, '2020-02-18'),
    ('Midwest Industrial Group', 'Stephanie Davis', 'sdavis@midwestindustrial.com', '312-555-6304', '3500 S Kedzie Ave', 'Chicago', 'Illinois', '60632', 275000.00, TRUE, '2019-06-15'),
    ('Loop Commercial Contractors', 'Robert Thompson', 'rthompson@loopcontractors.com', '312-555-6305', '150 N Wacker Dr', 'Chicago', 'Illinois', '60606', 225000.00, TRUE, '2018-11-10'),
    ('Wrigleyville Restoration', 'Katherine Martinez', 'kmartinez@wrigleyvillerestoration.com', '312-555-6306', '1060 W Addison St', 'Chicago', 'Illinois', '60613', 60000.00, TRUE, '2021-01-22'),
    ('South Side Development Corp', 'Timothy Johnson', 'tjohnson@southsidedev.com', '312-555-6307', '1901 S Indiana Ave', 'Chicago', 'Illinois', '60616', 110000.00, TRUE, '2020-04-18'),
    ('Chicago Municipal Projects', 'Alexandra Robinson', 'arobinson@chicagomunicipal.gov', '312-555-6308', '121 N LaSalle St', 'Chicago', 'Illinois', '60602', 500000.00, TRUE, '2017-09-30'),
    ('North Shore Construction', 'Patrick Evans', 'pevans@northshoreconstruction.com', '312-555-6309', '1603 Orrington Ave', 'Evanston', 'Illinois', '60201', 130000.00, TRUE, '2019-05-15'),
    ('O''Hare Expansion Group', 'Vanessa Garcia', 'vgarcia@ohareexpansion.com', '312-555-6310', '10000 W O''Hare Ave', 'Chicago', 'Illinois', '60666', 450000.00, TRUE, '2018-07-17'),
    ('Magnificent Mile Developers', 'Christopher Lee', 'clee@magmiledev.com', '312-555-6311', '400 N Michigan Ave', 'Chicago', 'Illinois', '60611', 175000.00, TRUE, '2020-03-10'),
    ('Pilsen Neighborhood Builders', 'Maria Rodriguez', 'mrodriguez@pilsenbuilders.com', '312-555-6312', '1800 S Blue Island Ave', 'Chicago', 'Illinois', '60608', 80000.00, TRUE, '2021-02-25'),
    ('Navy Pier Construction', 'Jonathan White', 'jwhite@navypierconstruction.com', '312-555-6313', '600 E Grand Ave', 'Chicago', 'Illinois', '60611', 220000.00, TRUE, '2019-08-22'),
    ('Hyde Park Renovation Group', 'Samantha Clark', 'sclark@hydeparkrenovation.com', '312-555-6314', '5300 S Lake Shore Dr', 'Chicago', 'Illinois', '60615', 95000.00, TRUE, '2020-06-15'),
    ('West Loop Development', 'Matthew Brown', 'mbrown@westloopdev.com', '312-555-6315', '950 W Fulton Market', 'Chicago', 'Illinois', '60607', 170000.00, TRUE, '2019-11-08'),
    ('McCormick Place Contractors', 'Rebecca Smith', 'rsmith@mccormickcontractors.com', '312-555-6316', '2301 S King Dr', 'Chicago', 'Illinois', '60616', 260000.00, TRUE, '2018-10-12'),
    ('Chicago Southland Industrial', 'Zachary Anderson', 'zanderson@southlandindustrial.com', '312-555-6317', '15101 S Halsted St', 'Harvey', 'Illinois', '60426', 190000.00, TRUE, '2020-01-20'),
    ('Calumet Harbor Construction', 'Victoria Johnson', 'vjohnson@calumetconstruction.com', '312-555-6318', '9501 S Ewing Ave', 'Chicago', 'Illinois', '60617', 230000.00, TRUE, '2019-07-05'),
    ('Lincoln Park Builders', 'Nathan Lewis', 'nlewis@lincolnparkbuilders.com', '312-555-6319', '2001 N Clark St', 'Chicago', 'Illinois', '60614', 85000.00, TRUE, '2020-09-18'),
    ('Chicago Bridges & Infrastructure', 'Danielle Turner', 'dturner@chicagobridges.com', '312-555-6320', '100 S Wacker Dr', 'Chicago', 'Illinois', '60606', 320000.00, TRUE, '2018-05-24'),
    ('Uptown Urban Renewal', 'Brian Martinez', 'bmartinez@uptownrenewal.com', '312-555-6321', '4500 N Broadway', 'Chicago', 'Illinois', '60640', 75000.00, TRUE, '2021-03-11'),
    ('Chicago Riverwalk Expansion', 'Tiffany Walker', 'twalker@riverwalkexpansion.com', '312-555-6322', '305 W Wacker Dr', 'Chicago', 'Illinois', '60606', 240000.00, TRUE, '2019-10-15'),
    ('Englewood Community Builders', 'Marcus Henderson', 'mhenderson@englewoodbuilders.com', '312-555-6323', '6300 S Halsted St', 'Chicago', 'Illinois', '60621', 55000.00, TRUE, '2020-07-28'),
    ('Schaumburg Business District', 'Olivia Parker', 'oparker@schaumburgdistrict.com', '312-555-6324', '1400 E Golf Rd', 'Schaumburg', 'Illinois', '60173', 125000.00, TRUE, '2019-04-10'),
    ('Midway Airport Development', 'Justin Campbell', 'jcampbell@midwaydev.com', '312-555-6325', '5700 S Cicero Ave', 'Chicago', 'Illinois', '60638', 280000.00, TRUE, '2018-12-05'),
    
    -- Miami Customers (22 customers)
    ('South Beach Construction', 'Carlos Rodriguez', 'crodriguez@southbeachconstruction.com', '305-555-7301', '900 Ocean Dr', 'Miami Beach', 'Florida', '33139', 120000.00, TRUE, '2019-05-15'),
    ('Miami Waterfront Developers', 'Sophia Hernandez', 'shernandez@miamiwaterfront.com', '305-555-7302', '401 Biscayne Blvd', 'Miami', 'Florida', '33132', 180000.00, TRUE, '2018-09-22'),
    ('Brickell Building Group', 'Antonio Martinez', 'amartinez@brickellbuilding.com', '305-555-7303', '1200 Brickell Ave', 'Miami', 'Florida', '33131', 200000.00, TRUE, '2020-02-10'),
    ('Coral Gables Restoration', 'Isabella Gonzalez', 'igonzalez@coralgablesrestoration.com', '305-555-7304', '2151 LeJeune Rd', 'Coral Gables', 'Florida', '33134', 85000.00, TRUE, '2021-01-18'),
    ('Coconut Grove Development', 'Diego Morales', 'dmorales@coconutgrovedev.com', '305-555-7305', '3300 Grand Ave', 'Miami', 'Florida', '33133', 95000.00, TRUE, '2019-11-05'),
    ('Port of Miami Contractors', 'Elena Diaz', 'ediaz@portmiami.com', '305-555-7306', '1015 N America Way', 'Miami', 'Florida', '33132', 250000.00, TRUE, '2018-07-12'),
    ('Wynwood Urban Builders', 'Ricardo Suarez', 'rsuarez@wynwoodbuilders.com', '305-555-7307', '250 NW 23rd St', 'Miami', 'Florida', '33127', 110000.00, TRUE, '2020-04-25'),
    ('Doral Commercial Construction', 'Victoria Torres', 'vtorres@doralcommercial.com', '305-555-7308', '8300 NW 53rd St', 'Doral', 'Florida', '33166', 175000.00, TRUE, '2019-08-15'),
    ('Key Biscayne Luxury Homes', 'Gabriel Reyes', 'greyes@keybiscaynehomes.com', '305-555-7309', '200 Crandon Blvd', 'Key Biscayne', 'Florida', '33149', 140000.00, TRUE, '2020-06-10'),
    ('Miami-Dade Infrastructure', 'Daniela Ortiz', 'dortiz@miamidade.gov', '305-555-7310', '111 NW 1st St', 'Miami', 'Florida', '33128', 500000.00, TRUE, '2017-10-30'),
    ('Hialeah Industrial Services', 'Manuel Ramirez', 'mramirez@hialeahindustrial.com', '305-555-7311', '1500 W 84th St', 'Hialeah', 'Florida', '33014', 160000.00, TRUE, '2019-03-18'),
    ('Little Havana Revitalization', 'Carmen Vasquez', 'cvasquez@littlehavanarev.com', '305-555-7312', '1000 SW 8th St', 'Miami', 'Florida', '33130', 70000.00, TRUE, '2021-02-22'),
    ('Aventura Mall Expansion', 'Alejandro Cruz', 'acruz@aventuraexpansion.com', '305-555-7313', '19501 Biscayne Blvd', 'Aventura', 'Florida', '33180', 280000.00, TRUE, '2019-09-05'),
    ('Miami Beach Seawall Builders', 'Valentina Lopez', 'vlopez@miamiseawall.com', '305-555-7314', '1700 Convention Center Dr', 'Miami Beach', 'Florida', '33139', 220000.00, TRUE, '2018-11-15'),
    ('Downtown Miami Redevelopment', 'Javier Mendez', 'jmendez@downtownmiamiredev.com', '305-555-7315', '200 S Biscayne Blvd', 'Miami', 'Florida', '33131', 240000.00, TRUE, '2020-01-10'),
    ('Miami River Construction', 'Natalia Flores', 'nflores@miamiriverconstruction.com', '305-555-7316', '375 SW North River Dr', 'Miami', 'Florida', '33130', 130000.00, TRUE, '2019-07-22'),
    ('Sunny Isles Beach Developers', 'Eduardo Silva', 'esilva@sunnyislesdev.com', '305-555-7317', '17070 Collins Ave', 'Sunny Isles Beach', 'Florida', '33160', 195000.00, TRUE, '2020-05-18'),
    ('Little River District Builders', 'Patricia Gutierrez', 'pgutierrez@littleriverbuilders.com', '305-555-7318', '7500 NE 4th Ct', 'Miami', 'Florida', '33138', 90000.00, TRUE, '2021-03-05'),
    ('Miami Lakes Construction', 'Fernando Perez', 'fperez@miamilakesconstruction.com', '305-555-7319', '15000 NW 67th Ave', 'Miami Lakes', 'Florida', '33014', 105000.00, TRUE, '2019-10-12'),
    ('Miami Airport Development', 'Lucia Castro', 'lcastro@miaairportdev.com', '305-555-7320', '4200 NW 36th St', 'Miami', 'Florida', '33166', 260000.00, TRUE, '2018-08-24'),
    ('Homestead Agricultural Builders', 'Roberto Jimenez', 'rjimenez@homesteadbuilders.com', '305-555-7321', '1035 N Flagler Ave', 'Homestead', 'Florida', '33030', 75000.00, TRUE, '2020-11-15'),
    ('Fisher Island Elite Construction', 'Adriana Fuentes', 'afuentes@fisherislandelite.com', '305-555-7322', '1 Fisher Island Dr', 'Miami Beach', 'Florida', '33109', 350000.00, TRUE, '2019-04-18'),
    
-- Denver Customers (continued)
    ('Front Range Builders', 'Mark Thompson', 'mthompson@frontrangebuilders.com', '720-555-8303', '700 17th St', 'Denver', 'Colorado', '80202', 165000.00, TRUE, '2020-01-18'),
    ('Colorado Industrial Services', 'Amanda Nelson', 'anelson@coloradoindustrial.com', '720-555-8304', '4600 Brighton Blvd', 'Denver', 'Colorado', '80216', 210000.00, TRUE, '2019-06-15'),
    ('LoDo Restoration Group', 'Brian Mitchell', 'bmitchell@lodorestoration.com', '720-555-8305', '1900 16th St', 'Denver', 'Colorado', '80202', 90000.00, TRUE, '2021-02-22'),
    ('Denver Municipal Projects', 'Elizabeth Wilson', 'ewilson@denverprojects.gov', '720-555-8306', '1437 Bannock St', 'Denver', 'Colorado', '80202', 450000.00, TRUE, '2018-07-10'),
    ('Mountain View Construction', 'Daniel Harris', 'dharris@mountainviewconst.com', '720-555-8307', '2000 Colorado Blvd', 'Denver', 'Colorado', '80205', 130000.00, TRUE, '2020-03-18'),
    ('Highland Development Co.', 'Jessica Davis', 'jdavis@highlanddev.com', '720-555-8308', '3500 Navajo St', 'Denver', 'Colorado', '80211', 95000.00, TRUE, '2019-09-05'),
    ('Cherry Creek Builders', 'Christopher Adams', 'cadams@cherrycreekbuilders.com', '720-555-8309', '2800 E 1st Ave', 'Denver', 'Colorado', '80206', 110000.00, TRUE, '2020-05-15'),
    ('Denver Airport Expansion', 'Michelle Roberts', 'mroberts@denairportexp.com', '720-555-8310', '8500 Peña Blvd', 'Denver', 'Colorado', '80249', 300000.00, TRUE, '2018-11-30'),
    ('Boulder Construction Alliance', 'Steven Wright', 'swright@boulderconstalliance.com', '720-555-8311', '1777 Broadway', 'Boulder', 'Colorado', '80302', 125000.00, TRUE, '2019-08-22'),
    ('Union Station Redevelopment', 'Kimberly Taylor', 'ktaylor@unionstationredev.com', '720-555-8312', '1701 Wynkoop St', 'Denver', 'Colorado', '80202', 215000.00, TRUE, '2020-02-10'),
    ('Stapleton Community Builders', 'Andrew Jackson', 'ajackson@stapletonbuilders.com', '720-555-8313', '7350 E 29th Ave', 'Denver', 'Colorado', '80238', 80000.00, TRUE, '2021-01-15'),
    ('Golden Excavation Services', 'Laura Martinez', 'lmartinez@goldenexcavation.com', '720-555-8314', '600 12th St', 'Golden', 'Colorado', '80401', 100000.00, TRUE, '2019-11-18'),
    ('RiNo District Development', 'Timothy Cooper', 'tcooper@rinodevelopment.com', '720-555-8315', '3501 Wazee St', 'Denver', 'Colorado', '80216', 135000.00, TRUE, '2020-07-22'),
    ('Lakewood Commercial Contractors', 'Jennifer Phillips', 'jphillips@lakewoodcontractors.com', '720-555-8316', '141 Union Blvd', 'Lakewood', 'Colorado', '80228', 115000.00, TRUE, '2019-05-10'),
    ('Denver Tech Center Builders', 'Michael White', 'mwhite@dtcbuilders.com', '720-555-8317', '8000 E Belleview Ave', 'Greenwood Village', 'Colorado', '80111', 170000.00, TRUE, '2018-10-05'),
    ('Platte River Restoration', 'Nicole Brown', 'nbrown@platterestoration.com', '720-555-8318', '2250 15th St', 'Denver', 'Colorado', '80202', 75000.00, TRUE, '2020-09-12'),
    ('Colorado Springs Development', 'Robert Lewis', 'rlewis@cospdevelopment.com', '720-555-8319', '121 S Tejon St', 'Colorado Springs', 'Colorado', '80903', 140000.00, TRUE, '2019-12-15'),
    ('Denver Infrastructure Alliance', 'Sarah Young', 'syoung@denverinfrastructure.com', '720-555-8320', '1144 Broadway', 'Denver', 'Colorado', '80203', 230000.00, TRUE, '2018-08-17'),
    
    -- Atlanta Customers (20 customers)
    ('Peachtree Construction Group', 'David Wilson', 'dwilson@peachtreeconstruction.com', '404-555-9301', '1180 Peachtree St NE', 'Atlanta', 'Georgia', '30309', 160000.00, TRUE, '2019-05-15'),
    ('Atlanta Metropolitan Builders', 'Tanya Johnson', 'tjohnson@atlmetrobuilders.com', '404-555-9302', '55 Allen Plaza', 'Atlanta', 'Georgia', '30308', 185000.00, TRUE, '2018-09-22'),
    ('Georgia Industrial Development', 'Marcus Bailey', 'mbailey@georgiaindustrial.com', '404-555-9303', '2200 Pleasantdale Rd', 'Atlanta', 'Georgia', '30340', 230000.00, TRUE, '2020-02-10'),
    ('Buckhead Commercial Contractors', 'Alicia Carter', 'acarter@buckheadcontractors.com', '404-555-9304', '3344 Peachtree Rd NE', 'Atlanta', 'Georgia', '30326', 175000.00, TRUE, '2019-07-18'),
    ('Midtown Atlanta Developers', 'Joshua Robinson', 'jrobinson@midtownatldevs.com', '404-555-9305', '999 Peachtree St NE', 'Atlanta', 'Georgia', '30309', 120000.00, TRUE, '2020-04-25'),
    ('Hartsfield Airport Construction', 'Vanessa Scott', 'vscott@hartsfieldconstruction.com', '404-555-9306', '6000 N Terminal Pkwy', 'Atlanta', 'Georgia', '30320', 350000.00, TRUE, '2018-06-12'),
    ('BeltLine Development Partners', 'Raymond Turner', 'rturner@beltlinedev.com', '404-555-9307', '725 Ponce De Leon Ave NE', 'Atlanta', 'Georgia', '30306', 140000.00, TRUE, '2019-10-15'),
    ('Downtown Revitalization Corp', 'Felicia Ward', 'fward@downtownrev.com', '404-555-9308', '191 Peachtree St NE', 'Atlanta', 'Georgia', '30303', 195000.00, TRUE, '2020-01-20'),
    ('College Park Industrial', 'Terrence Morris', 'tmorris@collegeparkindustrial.com', '404-555-9309', '1800 Sullivan Rd', 'College Park', 'Georgia', '30337', 170000.00, TRUE, '2019-08-08'),
    ('Georgia DOT Projects', 'Karla Gonzalez', 'kgonzalez@gadotprojects.gov', '404-555-9310', '600 W Peachtree St NW', 'Atlanta', 'Georgia', '30308', 500000.00, TRUE, '2017-11-30'),
    ('Perimeter Center Builders', 'Keith Fleming', 'kfleming@perimeterbuilders.com', '404-555-9311', '4400 Ashford Dunwoody Rd', 'Atlanta', 'Georgia', '30346', 165000.00, TRUE, '2018-10-22'),
    ('Marietta Development Group', 'Natasha Phillips', 'nphillips@mariettadevelopment.com', '404-555-9312', '50 Powder Springs St', 'Marietta', 'Georgia', '30064', 95000.00, TRUE, '2020-06-15'),
    ('Atlantic Station Construction', 'Darnell Washington', 'dwashington@atlanticstationconst.com', '404-555-9313', '1380 Atlantic Dr NW', 'Atlanta', 'Georgia', '30363', 210000.00, TRUE, '2019-03-10'),
    ('Decatur Urban Builders', 'Monica Reed', 'mreed@decaturbuilders.com', '404-555-9314', '101 E Court Square', 'Decatur', 'Georgia', '30030', 85000.00, TRUE, '2021-02-05'),
    ('Airport District Development', 'Trevor Jackson', 'tjackson@airportdistrictdev.com', '404-555-9315', '2200 Riverdale Rd', 'College Park', 'Georgia', '30337', 150000.00, TRUE, '2019-11-18'),
    ('Stone Mountain Contractors', 'Erica Hall', 'ehall@stonemountaincontractors.com', '404-555-9316', '5007 Memorial Dr', 'Stone Mountain', 'Georgia', '30083', 110000.00, TRUE, '2020-03-22'),
    ('Alpharetta Commercial Construction', 'Calvin Simmons', 'csimmons@alpharettacommercial.com', '404-555-9317', '2400 Old Milton Pkwy', 'Alpharetta', 'Georgia', '30009', 130000.00, TRUE, '2019-07-05'),
    ('Cumberland Mall Redevelopment', 'Shannon Bryant', 'sbryant@cumberlandredev.com', '404-555-9318', '2860 Cumberland Mall SE', 'Atlanta', 'Georgia', '30339', 240000.00, TRUE, '2018-09-12'),
    ('Cobb County Infrastructure', 'Darren Miller', 'dmiller@cobbinfrastructure.com', '404-555-9319', '100 Cherokee St', 'Marietta', 'Georgia', '30090', 190000.00, TRUE, '2020-05-10'),
    ('Sandy Springs Builders', 'Latoya Evans', 'levans@sandyspringsbuilders.com', '404-555-9320', '1 Galambos Way', 'Sandy Springs', 'Georgia', '30328', 100000.00, TRUE, '2019-12-15');
-- Insert data into inventory_locations table
INSERT INTO inventory_locations (location_name, address, city, state, postal_code, phone, is_active)
VALUES
    ('Seattle Equipment Center', '4215 Industrial Way', 'Seattle', 'Washington', '98108', '206-555-7890', TRUE),
    ('Houston Heavy Machinery Hub', '8742 Port Highway', 'Houston', 'Texas', '77029', '713-555-3421', TRUE),
    ('Chicago Construction Depot', '1577 South Canal Street', 'Chicago', 'Illinois', '60616', '312-555-9876', TRUE),
    ('Miami Equipment Yard', '2301 NW 87th Avenue', 'Miami', 'Florida', '33172', '305-555-2468', TRUE),
    ('Denver Mountain Operations', '5280 Colorado Boulevard', 'Denver', 'Colorado', '80216', '720-555-1357', TRUE),
    ('Atlanta Southeast Center', '3845 Fulton Industrial Blvd', 'Atlanta', 'Georgia', '30336', '404-555-6543', TRUE);
-- First, let's create the employees (without assigning primary_location_id yet since there's a circular reference)
INSERT INTO employees (first_name, last_name, position, email, phone, hire_date, certification, is_active)
VALUES
    -- Seattle Employees (Larger City - 8 employees + 1 manager)
    ('Michael', 'Chen', 'Branch Manager', 'mchen@heavyrentalco.com', '206-555-1001', '2019-06-15', ARRAY['OSHA Certified', 'Equipment Management Certification'], TRUE),
    ('Sarah', 'Johnson', 'Operations Supervisor', 'sjohnson@heavyrentalco.com', '206-555-1002', '2020-03-22', ARRAY['OSHA Certified', 'Heavy Equipment Operator License'], TRUE),
    ('David', 'Wilson', 'Senior Equipment Technician', 'dwilson@heavyrentalco.com', '206-555-1003', '2018-11-10', ARRAY['Diesel Mechanic Certification', 'Hydraulic Systems Specialist'], TRUE),
    ('Emily', 'Rodriguez', 'Rental Coordinator', 'erodriguez@heavyrentalco.com', '206-555-1004', '2021-02-15', ARRAY['Customer Service Certification'], TRUE),
    ('James', 'Taylor', 'Equipment Operator', 'jtaylor@heavyrentalco.com', '206-555-1005', '2020-08-17', ARRAY['CDL Class A', 'Crane Operator Certification'], TRUE),
    ('Maria', 'Garcia', 'Maintenance Technician', 'mgarcia@heavyrentalco.com', '206-555-1006', '2022-01-10', ARRAY['Mobile Equipment Maintenance Certification'], TRUE),
    ('Robert', 'Lee', 'Delivery Driver', 'rlee@heavyrentalco.com', '206-555-1007', '2021-05-22', ARRAY['CDL Class A', 'Hazmat Endorsement'], TRUE),
    ('Jennifer', 'Wong', 'Equipment Specialist', 'jwong@heavyrentalco.com', '206-555-1008', '2022-03-15', ARRAY['Equipment Sales Certification'], TRUE),
    ('Thomas', 'Anderson', 'Safety Coordinator', 'tanderson@heavyrentalco.com', '206-555-1009', '2019-09-20', ARRAY['OSHA Safety Manager Certification', 'First Aid Instructor'], TRUE),
    
    -- Houston Employees (Larger City - 7 employees + 1 manager)
    ('Carlos', 'Martinez', 'Branch Manager', 'cmartinez@heavyrentalco.com', '713-555-2001', '2018-04-10', ARRAY['OSHA Certified', 'MBA', 'Equipment Management Certification'], TRUE),
    ('Jessica', 'Brown', 'Operations Supervisor', 'jbrown@heavyrentalco.com', '713-555-2002', '2019-08-15', ARRAY['OSHA Certified', 'Project Management Professional'], TRUE),
    ('William', 'Jackson', 'Senior Equipment Technician', 'wjackson@heavyrentalco.com', '713-555-2003', '2020-01-22', ARRAY['Master Mechanic Certification', 'Welding Certification'], TRUE),
    ('Amanda', 'Davis', 'Rental Coordinator', 'adavis@heavyrentalco.com', '713-555-2004', '2021-03-18', ARRAY['Sales Certification', 'Customer Service Excellence'], TRUE),
    ('Luis', 'Hernandez', 'Equipment Operator', 'lhernandez@heavyrentalco.com', '713-555-2005', '2019-11-10', ARRAY['CDL Class A', 'Heavy Equipment Operator Certification'], TRUE),
    ('Samantha', 'Clark', 'Maintenance Technician', 'sclark@heavyrentalco.com', '713-555-2006', '2022-02-15', ARRAY['Diesel Engine Specialist', 'Hydraulic Systems Certification'], TRUE),
    ('Richard', 'Thompson', 'Delivery Driver', 'rthompson@heavyrentalco.com', '713-555-2007', '2020-09-05', ARRAY['CDL Class A', 'Hazmat Endorsement'], TRUE),
    ('Kelly', 'White', 'Yard Coordinator', 'kwhite@heavyrentalco.com', '713-555-2008', '2021-06-12', ARRAY['Inventory Management Certification', 'Forklift Operator'], TRUE),
    
    -- Chicago Employees (Larger City - 6 employees + 1 manager)
    ('Daniel', 'Miller', 'Branch Manager', 'dmiller@heavyrentalco.com', '312-555-3001', '2017-07-15', ARRAY['OSHA Certified', 'Equipment Management Certification', 'MBA'], TRUE),
    ('Nicole', 'Harris', 'Operations Supervisor', 'nharris@heavyrentalco.com', '312-555-3002', '2019-05-20', ARRAY['OSHA Certified', 'Project Management Professional'], TRUE),
    ('Anthony', 'Robinson', 'Senior Equipment Technician', 'arobinson@heavyrentalco.com', '312-555-3003', '2018-09-15', ARRAY['Master Mechanic Certification', 'Electrical Systems Specialist'], TRUE),
    ('Stephanie', 'Lewis', 'Rental Coordinator', 'slewis@heavyrentalco.com', '312-555-3004', '2020-04-22', ARRAY['Customer Service Certification', 'Sales Training'], TRUE),
    ('Marcus', 'Walker', 'Equipment Operator', 'mwalker@heavyrentalco.com', '312-555-3005', '2019-10-10', ARRAY['CDL Class A', 'Multiple Equipment Operator Licenses'], TRUE),
    ('Olivia', 'Allen', 'Maintenance Technician', 'oallen@heavyrentalco.com', '312-555-3006', '2021-01-18', ARRAY['HVAC Certification', 'Preventative Maintenance Specialist'], TRUE),
    ('George', 'Scott', 'Delivery Driver', 'gscott@heavyrentalco.com', '312-555-3007', '2020-07-05', ARRAY['CDL Class A', 'Tanker Endorsement'], TRUE),
    
    -- Miami Employees (Medium City - 5 employees + 1 manager)
    ('Alejandro', 'Rodriguez', 'Branch Manager', 'arodriguez@heavyrentalco.com', '305-555-4001', '2018-03-10', ARRAY['OSHA Certified', 'Business Administration Degree'], TRUE),
    ('Sophia', 'Perez', 'Operations Supervisor', 'sperez@heavyrentalco.com', '305-555-4002', '2019-06-15', ARRAY['OSHA Certified', 'Supply Chain Management'], TRUE),
    ('Brian', 'Turner', 'Senior Equipment Technician', 'bturner@heavyrentalco.com', '305-555-4003', '2020-02-22', ARRAY['Hydraulic Systems Specialist', 'Diesel Engine Certification'], TRUE),
    ('Isabella', 'Sanchez', 'Rental Coordinator', 'isanchez@heavyrentalco.com', '305-555-4004', '2021-04-18', ARRAY['Bilingual Customer Service', 'Sales Certification'], TRUE),
    ('Tyler', 'Morris', 'Equipment Operator', 'tmorris@heavyrentalco.com', '305-555-4005', '2019-09-10', ARRAY['CDL Class A', 'Marine Equipment Experience'], TRUE),
    ('Natalie', 'Diaz', 'Maintenance Technician', 'ndiaz@heavyrentalco.com', '305-555-4006', '2022-01-15', ARRAY['Mechanical Engineering Degree', 'Welding Certification'], TRUE),
    
    -- Denver Employees (Medium City - 4 employees + 1 manager)
    ('Christopher', 'Baker', 'Branch Manager', 'cbaker@heavyrentalco.com', '720-555-5001', '2019-02-15', ARRAY['OSHA Certified', 'Business Management Degree'], TRUE),
    ('Rebecca', 'Adams', 'Operations Supervisor', 'radams@heavyrentalco.com', '720-555-5002', '2020-04-22', ARRAY['OSHA Certified', 'Logistics Management'], TRUE),
    ('Justin', 'Phillips', 'Senior Equipment Technician', 'jphillips@heavyrentalco.com', '720-555-5003', '2018-08-10', ARRAY['Electrical Systems Specialist', 'Hydraulic Certification'], TRUE),
    ('Lauren', 'Campbell', 'Rental Coordinator', 'lcampbell@heavyrentalco.com', '720-555-5004', '2021-03-18', ARRAY['Contract Management', 'Customer Service Excellence'], TRUE),
    ('Kevin', 'Evans', 'Equipment Operator', 'kevans@heavyrentalco.com', '720-555-5005', '2020-07-15', ARRAY['CDL Class A', 'Mountain Operation Experience', 'Snow Equipment Specialist'], TRUE),
    
    -- Atlanta Employees (Medium City - 5 employees + 1 manager)
    ('Jonathan', 'Coleman', 'Branch Manager', 'jcoleman@heavyrentalco.com', '404-555-6001', '2018-05-10', ARRAY['OSHA Certified', 'Equipment Management Certification'], TRUE),
    ('Michelle', 'Foster', 'Operations Supervisor', 'mfoster@heavyrentalco.com', '404-555-6002', '2019-07-22', ARRAY['OSHA Certified', 'Project Scheduling Certification'], TRUE),
    ('Brandon', 'Russell', 'Senior Equipment Technician', 'brussell@heavyrentalco.com', '404-555-6003', '2020-03-15', ARRAY['Powertrain Specialist', 'Electronics Diagnostics'], TRUE),
    ('Rachel', 'Jenkins', 'Rental Coordinator', 'rjenkins@heavyrentalco.com', '404-555-6004', '2021-01-18', ARRAY['Account Management', 'Customer Service Training'], TRUE),
    ('Derrick', 'Howard', 'Equipment Operator', 'dhoward@heavyrentalco.com', '404-555-6005', '2019-11-10', ARRAY['CDL Class A', 'Excavator Specialist'], TRUE),
    ('Angela', 'Price', 'Maintenance Technician', 'aprice@heavyrentalco.com', '404-555-6006', '2022-02-15', ARRAY['Preventative Maintenance Certification'], TRUE);
    
-- Now update inventory_locations with manager references
UPDATE inventory_locations SET manager_id = 1 WHERE location_id = 1; -- Michael Chen manages Seattle
UPDATE inventory_locations SET manager_id = 10 WHERE location_id = 2; -- Carlos Martinez manages Houston
UPDATE inventory_locations SET manager_id = 18 WHERE location_id = 3; -- Daniel Miller manages Chicago
UPDATE inventory_locations SET manager_id = 25 WHERE location_id = 4; -- Alejandro Rodriguez manages Miami
UPDATE inventory_locations SET manager_id = 31 WHERE location_id = 5; -- Christopher Baker manages Denver
UPDATE inventory_locations SET manager_id = 36 WHERE location_id = 6; -- Jonathan Coleman manages Atlanta

-- Now update employees with their primary_location_id
-- Seattle employees
UPDATE employees SET primary_location_id = 1 WHERE employee_id BETWEEN 1 AND 9;
-- Houston employees
UPDATE employees SET primary_location_id = 2 WHERE employee_id BETWEEN 10 AND 17;
-- Chicago employees
UPDATE employees SET primary_location_id = 3 WHERE employee_id BETWEEN 18 AND 24;
-- Miami employees
UPDATE employees SET primary_location_id = 4 WHERE employee_id BETWEEN 25 AND 30;
-- Denver employees
UPDATE employees SET primary_location_id = 5 WHERE employee_id BETWEEN 31 AND 35;
-- Atlanta employees
UPDATE employees SET primary_location_id = 6 WHERE employee_id BETWEEN 36 AND 41;

-- Create employee location assignments (making sure all employees are assigned to their primary location)
INSERT INTO employee_locations (employee_id, location_id, is_primary, start_date, assignment_type)
VALUES
    -- Seattle employees
    (1, 1, TRUE, '2019-06-15', 'Permanent'),
    (2, 1, TRUE, '2020-03-22', 'Permanent'),
    (3, 1, TRUE, '2018-11-10', 'Permanent'),
    (4, 1, TRUE, '2021-02-15', 'Permanent'),
    (5, 1, TRUE, '2020-08-17', 'Permanent'),
    (6, 1, TRUE, '2022-01-10', 'Permanent'),
    (7, 1, TRUE, '2021-05-22', 'Permanent'),
    (8, 1, TRUE, '2022-03-15', 'Permanent'),
    (9, 1, TRUE, '2019-09-20', 'Permanent'),
    
    -- Houston employees
    (10, 2, TRUE, '2018-04-10', 'Permanent'),
    (11, 2, TRUE, '2019-08-15', 'Permanent'),
    (12, 2, TRUE, '2020-01-22', 'Permanent'),
    (13, 2, TRUE, '2021-03-18', 'Permanent'),
    (14, 2, TRUE, '2019-11-10', 'Permanent'),
    (15, 2, TRUE, '2022-02-15', 'Permanent'),
    (16, 2, TRUE, '2020-09-05', 'Permanent'),
    (17, 2, TRUE, '2021-06-12', 'Permanent'),
    
    -- Chicago employees
    (18, 3, TRUE, '2017-07-15', 'Permanent'),
    (19, 3, TRUE, '2019-05-20', 'Permanent'),
    (20, 3, TRUE, '2018-09-15', 'Permanent'),
    (21, 3, TRUE, '2020-04-22', 'Permanent'),
    (22, 3, TRUE, '2019-10-10', 'Permanent'),
    (23, 3, TRUE, '2021-01-18', 'Permanent'),
    (24, 3, TRUE, '2020-07-05', 'Permanent'),
    
    -- Miami employees
    (25, 4, TRUE, '2018-03-10', 'Permanent'),
    (26, 4, TRUE, '2019-06-15', 'Permanent'),
    (27, 4, TRUE, '2020-02-22', 'Permanent'),
    (28, 4, TRUE, '2021-04-18', 'Permanent'),
    (29, 4, TRUE, '2019-09-10', 'Permanent'),
    (30, 4, TRUE, '2022-01-15', 'Permanent'),
    
    -- Denver employees
    (31, 5, TRUE, '2019-02-15', 'Permanent'),
    (32, 5, TRUE, '2020-04-22', 'Permanent'),
    (33, 5, TRUE, '2018-08-10', 'Permanent'),
    (34, 5, TRUE, '2021-03-18', 'Permanent'),
    (35, 5, TRUE, '2020-07-15', 'Permanent'),
    
    -- Atlanta employees
    (36, 6, TRUE, '2018-05-10', 'Permanent'),
    (37, 6, TRUE, '2019-07-22', 'Permanent'),
    (38, 6, TRUE, '2020-03-15', 'Permanent'),
    (39, 6, TRUE, '2021-01-18', 'Permanent'),
    (40, 6, TRUE, '2019-11-10', 'Permanent'),
    (41, 6, TRUE, '2022-02-15', 'Permanent'),
    
    -- Some employees with secondary assignments (rotational or temporary)
    (3, 2, FALSE, '2023-01-15', 'Temporary'), -- Seattle technician helping in Houston
    (12, 1, FALSE, '2023-02-10', 'Temporary'), -- Houston technician helping in Seattle
    (20, 6, FALSE, '2022-11-15', 'Rotating'), -- Chicago technician rotating to Atlanta
    (27, 5, FALSE, '2023-03-01', 'Temporary'), -- Miami technician helping in Denver
    (38, 4, FALSE, '2022-12-01', 'Rotating'); -- Atlanta technician rotating to Miami
-- First, let's create equipment categories
INSERT INTO equipment_categories (category_name, description, daily_insurance_rate)
VALUES
    ('Excavator', 'Hydraulic excavators for digging and material handling', 75.00),
    ('Loader', 'Front loaders for moving materials', 65.00),
    ('Bulldozer', 'Tracked vehicles for pushing large quantities of soil', 85.00),
    ('Skid Steer', 'Compact loaders for tight spaces', 45.00),
    ('Backhoe', 'Combination of excavator and loader capabilities', 60.00),
    ('Trencher', 'Machines for digging trenches', 40.00),
    ('Compactor', 'Equipment for soil and asphalt compaction', 35.00),
    ('Concrete Mixer', 'For mixing and delivering concrete', 30.00),
    ('Generator', 'Mobile power generation units', 25.00),
    ('Air Compressor', 'High-pressure air supply equipment', 20.00),
    ('Forklift', 'Material handling equipment for lifting and moving', 35.00),
    ('Scissor Lift', 'Vertical lifting platforms', 40.00),
    ('Boom Lift', 'Aerial work platforms with extensible arms', 55.00),
    ('Telehandler', 'Telescopic handlers for lifting at height and reach', 70.00),
    ('Light Tower', 'Mobile lighting systems for work sites', 15.00);

-- Now insert equipment (at least 2 of each type across all locations)
INSERT INTO equipment (category_id, equipment_name, model_number, manufacturer, purchase_date, purchase_price, current_value, daily_rental_rate, weekly_rental_rate, monthly_rental_rate, status, maintenance_interval, last_maintenance_date, hours_used, condition_rating, location_id, notes)
VALUES
    -- Excavators
    (1, 'CAT 320 Excavator', '320-GC-2022', 'Caterpillar', '2022-03-15', 225000.00, 198000.00, 450.00, 2700.00, 9000.00, 'Available', 250, '2024-02-10', 1250, 4, 1, 'Medium-sized excavator with standard bucket'),
    (1, 'Komatsu PC210 Excavator', 'PC210LC-11', 'Komatsu', '2023-01-20', 235000.00, 220000.00, 475.00, 2850.00, 9500.00, 'Available', 250, '2024-01-05', 750, 5, 2, 'Includes quick coupler and hydraulic thumb'),
    (1, 'Hitachi ZX130 Excavator', 'ZX130-6', 'Hitachi', '2022-06-12', 175000.00, 155000.00, 350.00, 2100.00, 7000.00, 'Available', 200, '2024-02-20', 980, 4, 3, 'Compact excavator for urban projects'),
    (1, 'Volvo EC220 Excavator', 'EC220E', 'Volvo', '2021-11-25', 245000.00, 195000.00, 485.00, 2910.00, 9700.00, 'Maintenance', 250, '2024-03-01', 1680, 3, 4, 'Undergoing hydraulic system maintenance'),
    
    -- Loaders
    (2, 'CAT 966 Wheel Loader', '966M', 'Caterpillar', '2023-02-15', 320000.00, 305000.00, 550.00, 3300.00, 11000.00, 'Available', 300, '2024-01-15', 820, 5, 5, 'Large capacity general purpose bucket'),
    (2, 'John Deere 644 Loader', '644K', 'John Deere', '2022-05-10', 290000.00, 265000.00, 525.00, 3150.00, 10500.00, 'Rented', 300, '2023-12-10', 1120, 4, 6, 'Currently on rental at downtown project'),
    (2, 'Komatsu WA320 Loader', 'WA320-8', 'Komatsu', '2021-08-22', 260000.00, 220000.00, 500.00, 3000.00, 10000.00, 'Available', 300, '2024-02-05', 1520, 3, 1, 'Medium-sized loader with fork attachment available'),
    (2, 'Volvo L90 Loader', 'L90H', 'Volvo', '2023-04-18', 275000.00, 265000.00, 515.00, 3090.00, 10300.00, 'Available', 300, '2024-03-01', 590, 5, 2, 'Includes multi-purpose bucket and forks'),
    
    -- Bulldozers
    (3, 'CAT D6 Dozer', 'D6T', 'Caterpillar', '2022-09-30', 380000.00, 350000.00, 650.00, 3900.00, 13000.00, 'Available', 350, '2024-02-15', 980, 4, 3, 'Medium bulldozer with semi-U blade'),
    (3, 'Komatsu D65 Dozer', 'D65PX-18', 'Komatsu', '2023-03-12', 395000.00, 375000.00, 675.00, 4050.00, 13500.00, 'Rented', 350, '2024-01-10', 650, 5, 4, 'Wide track model for soft terrain'),
    (3, 'John Deere 700K Dozer', '700K', 'John Deere', '2021-11-15', 325000.00, 280000.00, 600.00, 3600.00, 12000.00, 'Available', 350, '2024-02-01', 1250, 3, 5, 'Smaller dozer with 6-way blade'),
    (3, 'Case 1650M Dozer', '1650M', 'Case', '2022-07-22', 340000.00, 310000.00, 625.00, 3750.00, 12500.00, 'Maintenance', 350, '2024-03-05', 875, 4, 6, 'Undergoing track replacement'),
    
    -- Skid Steers
    (4, 'Bobcat S76 Skid Steer', 'S76', 'Bobcat', '2023-05-10', 65000.00, 60000.00, 225.00, 1350.00, 4500.00, 'Available', 150, '2024-02-25', 450, 5, 1, 'Vertical lift path, includes bucket and forks'),
    (4, 'CAT 262D3 Skid Steer', '262D3', 'Caterpillar', '2022-08-15', 70000.00, 62000.00, 235.00, 1410.00, 4700.00, 'Available', 150, '2024-01-20', 780, 4, 2, 'High flow hydraulics package'),
    (4, 'John Deere 332G Skid Steer', '332G', 'John Deere', '2023-02-28', 68000.00, 64000.00, 230.00, 1380.00, 4600.00, 'Rented', 150, '2023-12-15', 410, 5, 3, 'Large capacity model with multiple attachments'),
    (4, 'Kubota SSV75 Skid Steer', 'SSV75', 'Kubota', '2022-10-05', 62000.00, 54000.00, 220.00, 1320.00, 4400.00, 'Available', 150, '2024-02-10', 650, 4, 4, 'Compact but powerful model'),
    
    -- Backhoes
    (5, 'JCB 3CX Backhoe', '3CX', 'JCB', '2022-04-18', 110000.00, 98000.00, 325.00, 1950.00, 6500.00, 'Available', 200, '2024-01-15', 920, 4, 5, 'Classic backhoe with extend-a-hoe feature'),
    (5, 'CAT 420 Backhoe', '420XE', 'Caterpillar', '2023-01-25', 130000.00, 122000.00, 345.00, 2070.00, 6900.00, 'Available', 200, '2024-02-20', 580, 5, 6, 'Premium model with pilot controls'),
    (5, 'Case 580 Backhoe', '580SN', 'Case', '2021-10-15', 115000.00, 95000.00, 330.00, 1980.00, 6600.00, 'Maintenance', 200, '2024-03-01', 1380, 3, 1, 'Undergoing boom repair'),
    (5, 'John Deere 310SL Backhoe', '310SL', 'John Deere', '2022-11-30', 125000.00, 112000.00, 340.00, 2040.00, 6800.00, 'Available', 200, '2024-01-10', 760, 4, 2, 'Tool carrier version with quick coupler'),
    
    -- Trenchers
    (6, 'Vermeer RTX550 Trencher', 'RTX550', 'Vermeer', '2023-03-20', 95000.00, 90000.00, 280.00, 1680.00, 5600.00, 'Available', 150, '2024-02-05', 410, 5, 3, 'Ride-on trencher with 6" chain'),
    (6, 'Ditch Witch RT45 Trencher', 'RT45', 'Ditch Witch', '2022-06-15', 85000.00, 75000.00, 260.00, 1560.00, 5200.00, 'Rented', 150, '2023-12-20', 680, 4, 4, 'With both trencher and backhoe attachments'),
    (6, 'Toro TRX-26 Trencher', 'TRX-26', 'Toro', '2022-09-10', 25000.00, 21000.00, 180.00, 1080.00, 3600.00, 'Available', 100, '2024-01-25', 520, 4, 5, 'Walk-behind model for tight access areas'),
    (6, 'Barreto 1824TK Trencher', '1824TK', 'Barreto', '2023-02-05', 22000.00, 20000.00, 175.00, 1050.00, 3500.00, 'Available', 100, '2024-02-15', 320, 5, 6, 'Track-mounted walk-behind trencher'),
    
    -- Compactors
    (7, 'CAT CB10 Roller', 'CB10', 'Caterpillar', '2022-08-25', 115000.00, 102000.00, 290.00, 1740.00, 5800.00, 'Available', 200, '2024-01-30', 780, 4, 1, 'Tandem vibratory roller for asphalt'),
    (7, 'Bomag BW211 Roller', 'BW211D-5', 'Bomag', '2023-04-10', 125000.00, 118000.00, 300.00, 1800.00, 6000.00, 'Available', 200, '2024-02-25', 450, 5, 2, 'Single drum soil compactor'),
    (7, 'Wacker RD12 Roller', 'RD12A', 'Wacker Neuson', '2022-05-20', 28000.00, 24000.00, 175.00, 1050.00, 3500.00, 'Rented', 150, '2023-11-15', 680, 4, 3, 'Small walk-behind roller'),
    (7, 'Multiquip MVC88 Plate Compactor', 'MVC88VTHW', 'Multiquip', '2023-01-15', 3500.00, 3200.00, 75.00, 450.00, 1500.00, 'Available', 100, '2024-02-10', 420, 5, 4, 'Forward plate compactor'),
    
    -- Concrete Mixers
    (8, 'Multiquip MC94S Mixer', 'MC94S', 'Multiquip', '2022-10-15', 3800.00, 3300.00, 85.00, 510.00, 1700.00, 'Available', 100, '2024-01-20', 550, 4, 5, '9 cubic foot concrete mixer'),
    (8, 'Crown C9 Mixer', 'C9', 'Crown Construction', '2023-03-05', 4200.00, 3900.00, 90.00, 540.00, 1800.00, 'Available', 100, '2024-02-20', 320, 5, 6, 'Heavy duty mixer with Honda engine'),
    (8, 'Terex Advance FD4000 Mixer Truck', 'FD4000', 'Terex', '2021-09-30', 195000.00, 165000.00, 450.00, 2700.00, 9000.00, 'Maintenance', 250, '2024-03-01', 1820, 3, 1, '11 cubic yard front discharge mixer truck'),
    (8, 'Oshkosh S-Series Mixer Truck', 'S-Series', 'Oshkosh', '2022-07-15', 210000.00, 185000.00, 475.00, 2850.00, 9500.00, 'Available', 250, '2024-01-15', 1250, 4, 2, '12 cubic yard rear discharge mixer truck'),
    
    -- Generators
    (9, 'Generac XG10000E Generator', 'XG10000E', 'Generac', '2023-01-10', 3500.00, 3200.00, 95.00, 570.00, 1900.00, 'Available', 100, '2024-02-05', 450, 5, 3, '10kW portable generator'),
    (9, 'Honda EB10000 Generator', 'EB10000', 'Honda', '2022-06-20', 6800.00, 6000.00, 115.00, 690.00, 2300.00, 'Available', 100, '2024-01-25', 680, 4, 4, '10kW industrial generator'),
    (9, 'CAT XQ230 Generator', 'XQ230', 'Caterpillar', '2021-11-15', 75000.00, 65000.00, 350.00, 2100.00, 7000.00, 'Rented', 200, '2023-12-10', 1450, 3, 5, '230kW towable generator'),
    (9, 'Cummins C150D6R Generator', 'C150D6R', 'Cummins', '2022-09-05', 65000.00, 59000.00, 325.00, 1950.00, 6500.00, 'Available', 200, '2024-02-15', 950, 4, 6, '150kW towable generator'),
    
    -- Air Compressors
    (10, 'Atlas Copco XAS 110 Compressor', 'XAS 110', 'Atlas Copco', '2022-05-28', 28000.00, 24000.00, 165.00, 990.00, 3300.00, 'Available', 150, '2024-01-20', 780, 4, 1, 'Towable 110 CFM diesel air compressor'),
    (10, 'Doosan P185 Compressor', 'P185WDO', 'Doosan', '2023-02-15', 30000.00, 28000.00, 175.00, 1050.00, 3500.00, 'Available', 150, '2024-02-10', 450, 5, 2, 'Towable 185 CFM diesel air compressor'),
    (10, 'Sullair 375H Compressor', '375H', 'Sullair', '2022-07-10', 52000.00, 46000.00, 225.00, 1350.00, 4500.00, 'Maintenance', 150, '2024-03-01', 950, 3, 3, 'Towable 375 CFM diesel air compressor'),
    (10, 'Ingersoll Rand VHP700 Compressor', 'VHP700WIR', 'Ingersoll Rand', '2021-12-18', 58000.00, 48000.00, 245.00, 1470.00, 4900.00, 'Available', 150, '2024-01-10', 1280, 4, 4, 'Towable 700 CFM diesel air compressor'),
    
    -- Forklifts
    (11, 'Toyota 8FGU25 Forklift', '8FGU25', 'Toyota', '2022-09-15', 35000.00, 31000.00, 195.00, 1170.00, 3900.00, 'Available', 150, '2024-02-05', 820, 4, 5, '5000 lb capacity propane forklift'),
    (11, 'Hyster H80FT Forklift', 'H80FT', 'Hyster', '2023-03-20', 38000.00, 36000.00, 205.00, 1230.00, 4100.00, 'Available', 150, '2024-01-25', 480, 5, 6, '8000 lb capacity diesel forklift'),
    (11, 'Crown FC 4500 Forklift', 'FC 4500', 'Crown', '2022-06-10', 32000.00, 28000.00, 185.00, 1110.00, 3700.00, 'Rented', 150, '2023-11-20', 960, 4, 1, '4000 lb capacity electric forklift'),
    (11, 'CAT DP70N Forklift', 'DP70N', 'Caterpillar', '2021-10-25', 65000.00, 55000.00, 275.00, 1650.00, 5500.00, 'Available', 200, '2024-02-15', 1320, 3, 2, '15000 lb capacity diesel forklift'),
    
    -- Scissor Lifts
    (12, 'Genie GS-1930 Scissor Lift', 'GS-1930', 'Genie', '2023-01-15', 15000.00, 14000.00, 150.00, 900.00, 3000.00, 'Available', 100, '2024-02-10', 420, 5, 3, '19 ft electric scissor lift'),
    (12, 'Skyjack SJIII 3219 Scissor Lift', 'SJIII 3219', 'Skyjack', '2022-05-20', 14500.00, 12500.00, 145.00, 870.00, 2900.00, 'Available', 100, '2024-01-20', 680, 4, 4, '19 ft electric scissor lift'),
    (12, 'JLG 4069LE Scissor Lift', '4069LE', 'JLG', '2022-08-10', 45000.00, 40000.00, 225.00, 1350.00, 4500.00, 'Maintenance', 150, '2024-02-28', 520, 4, 5, '40 ft electric rough terrain scissor lift'),
    (12, 'Hy-Brid HB-1430 Scissor Lift', 'HB-1430', 'Hy-Brid', '2023-04-05', 12000.00, 11500.00, 135.00, 810.00, 2700.00, 'Available', 100, '2024-02-15', 280, 5, 6, '14 ft lightweight scissor lift'),
    
    -- Boom Lifts
    (13, 'JLG 450AJ Boom Lift', '450AJ', 'JLG', '2022-07-12', 95000.00, 85000.00, 350.00, 2100.00, 7000.00, 'Available', 200, '2024-01-15', 780, 4, 1, '45 ft diesel articulating boom lift'),
    (13, 'Genie Z-45/25J Boom Lift', 'Z-45/25J', 'Genie', '2023-02-28', 98000.00, 93000.00, 365.00, 2190.00, 7300.00, 'Available', 200, '2024-02-20', 450, 5, 2, '45 ft diesel articulating boom lift'),
    (13, 'JLG 600S Boom Lift', '600S', 'JLG', '2021-11-10', 135000.00, 115000.00, 425.00, 2550.00, 8500.00, 'Rented', 200, '2023-12-05', 1250, 3, 3, '60 ft diesel straight boom lift'),
    (13, 'Genie S-65 Boom Lift', 'S-65', 'Genie', '2022-09-25', 140000.00, 126000.00, 440.00, 2640.00, 8800.00, 'Available', 200, '2024-01-30', 860, 4, 4, '65 ft diesel straight boom lift'),
    
    -- Telehandlers
    (14, 'JCB 507-42 Telehandler', '507-42', 'JCB', '2022-06-15', 110000.00, 98000.00, 385.00, 2310.00, 7700.00, 'Available', 200, '2024-02-05', 820, 4, 5, '7000 lb capacity, 42 ft reach telehandler'),
    (14, 'CAT TL943D Telehandler', 'TL943D', 'Caterpillar', '2023-03-10', 125000.00, 118000.00, 405.00, 2430.00, 8100.00, 'Available', 200, '2024-01-25', 480, 5, 6, '9000 lb capacity, 43 ft reach telehandler'),
    (14, 'Genie GTH-844 Telehandler', 'GTH-844', 'Genie', '2022-09-20', 145000.00, 130000.00, 425.00, 2550.00, 8500.00, 'Maintenance', 200, '2024-02-25', 750, 4, 1, '8000 lb capacity, 44 ft reach telehandler'),
    (14, 'JLG 1055 Telehandler', '1055', 'JLG', '2021-12-05', 155000.00, 130000.00, 450.00, 2700.00, 9000.00, 'Available', 200, '2024-01-10', 1180, 3, 2, '10000 lb capacity, 55 ft reach telehandler'),
    
    -- Light Towers
    (15, 'Generac MLT6 Light Tower', 'MLT6', 'Generac', '2023-01-25', 15000.00, 14000.00, 120.00, 720.00, 2400.00, 'Available', 100, '2024-02-15', 450, 5, 3, 'Towable light tower with 4 metal halide lamps'),
    (15, 'Doosan L8 Light Tower', 'L8', 'Doosan', '2022-08-15', 16500.00, 14500.00, 125.00, 750.00, 2500.00, 'Available', 100, '2024-01-20', 680, 4, 4, 'Towable light tower with LED lamps'),
    (15, 'Wacker Neuson LTV6 Light Tower', 'LTV6', 'Wacker Neuson', '2022-05-10', 14500.00, 12500.00, 115.00, 690.00, 2300.00, 'Rented', 100, '2023-11-15', 790, 4, 5, 'Vertical mast light tower'),
    (15, 'Terex AL5 Light Tower', 'AL5', 'Terex', '2023-04-05', 17000.00, 16500.00, 130.00, 780.00, 2600.00, 'Available', 100, '2024-02-10', 280, 5, 6, 'Compact light tower with LED technology');
-- Insert data into maintenance_records table
INSERT INTO maintenance_records (equipment_id, maintenance_date, maintenance_type, description, cost, performed_by, hours_added, parts_replaced, next_maintenance_date, status, notes)
VALUES
    -- Seattle Location Equipment Maintenance
    (1, '2023-08-15', 'Scheduled', '250-hour maintenance service including oil change, filter replacement, and hydraulic system check', 1250.00, 3, 0, 'Oil filters, hydraulic filters, air filters', '2024-02-10', 'Completed', 'Regular maintenance completed on schedule'),
    (1, '2024-02-10', 'Scheduled', '500-hour maintenance service with full fluid replacement and system diagnostics', 2100.00, 3, 0, 'All filters, hydraulic fluid, engine oil, coolant', '2024-08-10', 'Completed', 'Machine operating within specifications'),
    (2, '2023-07-05', 'Scheduled', '250-hour service maintenance performed', 1350.00, 3, 0, 'Oil filters, hydraulic filters', '2024-01-05', 'Completed', 'Regular maintenance completed on schedule'),
    (2, '2024-01-05', 'Scheduled', '500-hour comprehensive service', 2200.00, 3, 0, 'All filters, hydraulic fluid, engine oil', '2024-07-05', 'Completed', 'Extended service life expectancy'),
    (3, '2024-02-20', 'Scheduled', '250-hour maintenance check and fluid change', 1150.00, 6, 0, 'Oil filters, hydraulic filters, air filters', '2024-08-20', 'Completed', 'Machine in excellent condition'),
    (4, '2024-03-01', 'Repair', 'Hydraulic cylinder seal replacement and control valve adjustment', 3200.00, 3, 25, 'Hydraulic cylinder seals, control valve kit', '2024-09-01', 'Completed', 'Repair needed due to normal wear and tear'),
    (5, '2023-10-15', 'Scheduled', '300-hour maintenance service', 1450.00, 6, 0, 'All filters, engine oil', '2024-04-15', 'Completed', 'Regular maintenance performed'),
    (6, '2024-01-15', 'Inspection', 'Annual safety inspection and certification', 850.00, 3, 0, 'None', '2025-01-15', 'Completed', 'Machine passed all safety checks'),
    (7, '2023-12-10', 'Scheduled', '300-hour maintenance service', 1500.00, 6, 0, 'All filters, engine oil, transmission fluid', '2024-06-10', 'Completed', 'No issues found'),
    (8, '2024-03-20', 'Emergency', 'Hydraulic hose burst repair and system flush', 2800.00, 3, 15, 'Hydraulic hoses, hydraulic fluid', '2024-09-20', 'Completed', 'Emergency repair completed within 24 hours'),
    (13, '2024-01-20', 'Scheduled', '150-hour maintenance service', 750.00, 6, 0, 'Oil filter, air filter, fuel filter', '2024-07-20', 'Completed', 'Machine in good operating condition'),
    
    -- Houston Location Equipment Maintenance
    (10, '2023-09-10', 'Scheduled', '350-hour maintenance service', 1750.00, 12, 0, 'All filters, hydraulic fluid, engine oil', '2024-03-10', 'Completed', 'Regular maintenance performed'),
    (10, '2024-01-10', 'Repair', 'Track assembly replacement and undercarriage inspection', 4800.00, 12, 30, 'Track assembly, idler wheels', '2024-07-10', 'Completed', 'Wear and tear due to harsh terrain operation'),
    (11, '2023-12-15', 'Scheduled', '350-hour maintenance service', 1700.00, 15, 0, 'All filters, engine oil, hydraulic fluid', '2024-06-15', 'Completed', 'Regular maintenance performed'),
    (12, '2024-03-05', 'Scheduled', '350-hour maintenance check', 1800.00, 12, 0, 'All filters, engine oil, hydraulic fluid', '2024-09-05', 'In Progress', 'Machine temporarily out of service for maintenance'),
    (15, '2023-11-15', 'Scheduled', '150-hour service', 850.00, 15, 0, 'Oil filter, air filter', '2024-05-15', 'Completed', 'Minor adjustments made to hydraulic system'),
    (16, '2024-02-20', 'Repair', 'Chain drive adjustment and lubrication system repair', 1200.00, 12, 10, 'Chain tensioner, lubrication pump', '2024-08-20', 'Completed', 'Machine back in service after repairs'),
    (19, '2024-01-20', 'Scheduled', '200-hour maintenance service', 950.00, 15, 0, 'All filters, engine oil', '2024-07-20', 'Completed', 'Regular maintenance performed'),
    (22, '2023-10-20', 'Emergency', 'Engine overheating investigation and cooling system repair', 2500.00, 12, 25, 'Water pump, thermostat, coolant', '2024-04-20', 'Completed', 'Cooling system completely rebuilt'),
    
    -- Chicago Location Equipment Maintenance
    (20, '2023-09-15', 'Scheduled', '200-hour service check', 1100.00, 20, 0, 'All filters, engine oil', '2024-03-15', 'Completed', 'Regular maintenance performed'),
    (23, '2024-02-05', 'Scheduled', '200-hour maintenance service', 1150.00, 23, 0, 'All filters, engine oil', '2024-08-05', 'Completed', 'Machine in good operating condition'),
    (24, '2023-12-20', 'Repair', 'Boom cylinder seal replacement', 1800.00, 20, 15, 'Boom cylinder seals, hydraulic fluid', '2024-06-20', 'Completed', 'Repair due to normal wear and tear'),
    (27, '2024-01-25', 'Scheduled', '100-hour service', 650.00, 23, 0, 'Oil filter, air filter', '2024-07-25', 'Completed', 'Regular maintenance performed'),
    (29, '2023-11-10', 'Inspection', 'Annual safety certification and inspection', 800.00, 20, 0, 'None', '2024-11-10', 'Completed', 'All safety standards met'),
    (30, '2024-03-01', 'Emergency', 'Engine failure diagnosis and starter motor replacement', 1900.00, 23, 20, 'Starter motor, battery', '2024-09-01', 'Completed', 'Quick repair turnaround to minimize downtime'),
    (34, '2024-02-10', 'Scheduled', '150-hour maintenance check', 750.00, 20, 0, 'All filters, engine oil', '2024-08-10', 'Completed', 'Machine operating within specifications'),
    
    -- Miami Location Equipment Maintenance
    (33, '2023-10-05', 'Scheduled', '150-hour service', 800.00, 27, 0, 'All filters, engine oil', '2024-04-05', 'Completed', 'Regular maintenance performed'),
    (33, '2024-02-25', 'Repair', 'Control panel replacement and electrical system diagnosis', 2300.00, 27, 15, 'Control panel, wiring harness', '2024-08-25', 'Completed', 'Repair due to saltwater exposure damage'),
    (36, '2023-12-05', 'Scheduled', '150-hour maintenance check', 700.00, 30, 0, 'All filters, engine oil', '2024-06-05', 'Completed', 'Machine in good operating condition'),
    (39, '2024-01-30', 'Inspection', 'Safety compliance inspection', 550.00, 27, 0, 'None', '2025-01-30', 'Completed', 'All safety standards met'),
    (46, '2023-11-20', 'Scheduled', '200-hour maintenance service', 1050.00, 30, 0, 'All filters, hydraulic fluid, engine oil', '2024-05-20', 'Completed', 'Regular maintenance performed'),
    (53, '2024-03-15', 'Emergency', 'Boom failure investigation and hydraulic system repair', 3800.00, 27, 30, 'Hydraulic valves, hoses, boom cylinder', '2024-09-15', 'In Progress', 'Major repair to critical component'),
    
    -- Denver Location Equipment Maintenance
    (43, '2023-08-10', 'Scheduled', '200-hour maintenance check', 1050.00, 33, 0, 'All filters, engine oil', '2024-02-10', 'Completed', 'Regular maintenance performed'),
    (43, '2024-02-10', 'Scheduled', '400-hour comprehensive service', 1950.00, 33, 0, 'All filters, engine oil, hydraulic fluid, cooling system flush', '2024-08-10', 'Completed', 'Extended maintenance due to mountain operation'),
    (47, '2023-11-05', 'Repair', 'Air compressor rebuild', 1400.00, 33, 15, 'Compressor pump, pressure switch, air filters', '2024-05-05', 'Completed', 'Repair due to altitude operation stress'),
    (47, '2024-03-01', 'Inspection', 'State safety compliance inspection', 600.00, 33, 0, 'None', '2025-03-01', 'Completed', 'Passed all safety requirements'),
    (21, '2024-01-25', 'Scheduled', '100-hour service', 550.00, 33, 0, 'Oil filter, air filter', '2024-07-25', 'Completed', 'Regular maintenance performed'),
    (29, '2023-09-20', 'Scheduled', '150-hour maintenance', 750.00, 33, 0, 'All filters, engine oil', '2024-03-20', 'Completed', 'Machine in good operating condition'),
    
    -- Atlanta Location Equipment Maintenance
    (31, '2023-10-10', 'Scheduled', '150-hour service', 850.00, 38, 0, 'All filters, engine oil', '2024-04-10', 'Completed', 'Regular maintenance performed'),
    (31, '2024-02-15', 'Repair', 'Hydraulic pump replacement', 2200.00, 38, 20, 'Hydraulic pump, fittings, hydraulic fluid', '2024-08-15', 'Completed', 'Repair due to normal wear and tear'),
    (35, '2023-12-15', 'Scheduled', '100-hour maintenance', 600.00, 41, 0, 'Oil filter, air filter, fuel filter', '2024-06-15', 'Completed', 'Machine in good operating condition'),
    (44, '2024-01-05', 'Scheduled', '200-hour service check', 1100.00, 38, 0, 'All filters, engine oil, hydraulic fluid', '2024-07-05', 'Completed', 'Regular maintenance performed'),
    (44, '2024-03-10', 'Inspection', 'Annual certification and safety inspection', 750.00, 41, 0, 'None', '2025-03-10', 'Completed', 'All safety standards met'),
    (51, '2023-11-25', 'Emergency', 'Hydraulic system failure and contamination cleanup', 3500.00, 38, 25, 'Hydraulic pump, valves, filters, hydraulic fluid', '2024-05-25', 'Completed', 'Complete system flush and rebuild required'),
    (52, '2024-02-25', 'Scheduled', '200-hour maintenance service', 1150.00, 41, 0, 'All filters, engine oil', '2024-08-25', 'Completed', 'Machine operating within specifications'),
    (60, '2023-09-10', 'Scheduled', '100-hour service', 580.00, 38, 0, 'Oil filter, air filter', '2024-03-10', 'Completed', 'Regular maintenance performed'),
    (60, '2024-03-10', 'Scheduled', '200-hour comprehensive service', 950.00, 41, 0, 'All filters, engine oil, bulb replacement', '2024-09-10', 'In Progress', 'Scheduled maintenance in progress');
-- First, let's insert data into the rentals table
INSERT INTO rentals (customer_id, rental_date, expected_return_date, actual_return_date, total_amount, deposit_amount, deposit_returned, status, created_by, pickup_location_id, return_location_id, insurance_coverage, po_number, notes)
VALUES
    -- Seattle Rentals
    (1, '2024-02-15', '2024-02-22', '2024-02-22', 3750.00, 1000.00, TRUE, 'Completed', 2, 1, 1, TRUE, 'PO-PNWC-2402', 'Regular customer, no issues'),
    (3, '2024-01-10', '2024-01-25', '2024-01-27', 12600.00, 3000.00, TRUE, 'Completed', 4, 1, 1, TRUE, 'RDG-240110', 'Returned 2 days late, additional charges applied'),
    (8, '2024-02-25', '2024-03-10', NULL, 5950.00, 1500.00, FALSE, 'Active', 2, 1, 1, TRUE, 'PSC-240225', 'Multiple items for downtown project'),
    (5, '2024-03-01', '2024-03-31', NULL, 9700.00, 2500.00, FALSE, 'Active', 4, 1, 1, TRUE, 'CIL-24031', 'Monthly rental for bridge project'),
    (12, '2024-03-05', '2024-03-12', NULL, 4500.00, 1200.00, FALSE, 'Active', 2, 1, 1, TRUE, 'BMC-240305', 'Waterfront project equipment'),
    (2, '2024-03-15', '2024-03-18', NULL, 1350.00, 500.00, FALSE, 'Active', 4, 1, 1, TRUE, 'ECB-240315', 'Weekend project rental'),
    (15, '2024-03-20', '2024-04-03', NULL, 3600.00, 900.00, FALSE, 'Active', 2, 1, 1, TRUE, 'GLL-240320', 'Park renovation equipment'),
    (4, '2024-03-10', '2024-03-17', NULL, 2450.00, 800.00, FALSE, 'Active', 4, 1, 1, TRUE, 'SES-240310', 'Excavation equipment for new residential development'),
    (6, '2024-02-01', '2024-02-15', '2024-02-14', 8400.00, 2000.00, TRUE, 'Completed', 2, 1, 1, TRUE, 'OC-240201', 'Returned early, no additional charges'),
    (10, '2024-03-18', '2024-03-25', NULL, 5200.00, 1300.00, FALSE, 'Active', 4, 1, 1, FALSE, 'SMP-240318', 'Municipal project, insurance waived'),
    (7, '2024-01-05', '2024-01-12', '2024-01-12', 2800.00, 700.00, TRUE, 'Completed', 2, 1, 1, TRUE, 'EBS-240105', 'Regular delivery equipment'),
    
    -- Houston Rentals
    (32, '2024-01-15', '2024-02-15', '2024-02-17', 14500.00, 3500.00, TRUE, 'Completed', 11, 2, 2, TRUE, 'TOFSPO-240115', 'Oil field equipment, returned with minor damage'),
    (38, '2024-02-10', '2024-02-24', '2024-02-24', 9200.00, 2300.00, TRUE, 'Completed', 13, 2, 2, TRUE, 'WCDC-240210', 'The Woodlands development project'),
    (31, '2024-03-01', '2024-03-31', NULL, 11500.00, 2800.00, FALSE, 'Active', 11, 2, 2, TRUE, 'GCD-240301', 'Monthly rental for large development'),
    (35, '2024-02-20', '2024-03-05', '2024-03-04', 6800.00, 1700.00, TRUE, 'Completed', 13, 2, 2, TRUE, 'HMCD-240220', 'Medical center expansion equipment'),
    (33, '2024-03-10', '2024-03-24', NULL, 8400.00, 2100.00, FALSE, 'Active', 11, 2, 2, TRUE, 'BCC-240310', 'Bayou City waterfront project'),
    (40, '2024-03-15', '2024-04-15', NULL, 13200.00, 3300.00, FALSE, 'Active', 13, 2, 2, TRUE, 'HADA-240315', 'Airport expansion, monthly rental'),
    (34, '2024-03-05', '2024-03-12', NULL, 4500.00, 1100.00, FALSE, 'Active', 11, 2, 2, TRUE, 'HHC-240305', 'Harbor expansion project'),
    (37, '2024-01-25', '2024-02-01', '2024-02-02', 3800.00, 950.00, TRUE, 'Completed', 13, 2, 2, TRUE, 'MUD-240125', 'Midtown urban project, returned late'),
    (36, '2024-03-08', '2024-03-15', NULL, 3200.00, 800.00, FALSE, 'Active', 11, 2, 2, TRUE, 'HRS-240308', 'Heights renovation project'),
    (39, '2024-03-12', '2024-03-26', NULL, 7600.00, 1900.00, FALSE, 'Active', 13, 2, 2, TRUE, 'SLB-240312', 'Sugar Land commercial development'),
    
    -- Chicago Rentals
    (43, '2024-01-20', '2024-02-20', '2024-02-18', 13800.00, 3500.00, TRUE, 'Completed', 19, 3, 3, TRUE, 'CRB-240120', 'River front commercial development'),
    (49, '2024-02-05', '2024-02-19', '2024-02-19', 7200.00, 1800.00, TRUE, 'Completed', 21, 3, 3, TRUE, 'NSC-240205', 'North Shore residential project'),
    (45, '2024-03-01', '2024-03-15', NULL, 8400.00, 2100.00, FALSE, 'Active', 19, 3, 3, TRUE, 'LCC-240301', 'Loop commercial renovation'),
    (50, '2024-03-05', '2024-04-05', NULL, 15600.00, 3900.00, FALSE, 'Active', 21, 3, 3, TRUE, 'OEG-240305', 'O''Hare expansion equipment'),
    (46, '2024-02-15', '2024-02-22', '2024-02-23', 4200.00, 1050.00, TRUE, 'Completed', 19, 3, 3, TRUE, 'WVR-240215', 'Wrigleyville renovation, returned late'),
    (51, '2024-03-10', '2024-03-24', NULL, 8800.00, 2200.00, FALSE, 'Active', 21, 3, 3, TRUE, 'MMD-240310', 'Magnificent Mile storefront renovation'),
    (44, '2024-03-12', '2024-03-19', NULL, 4200.00, 1050.00, FALSE, 'Active', 19, 3, 3, TRUE, 'MIG-240312', 'Industrial park upgrades'),
    (48, '2024-01-15', '2024-01-29', '2024-01-29', 7600.00, 1900.00, TRUE, 'Completed', 21, 3, 3, FALSE, 'CMP-240115', 'Municipal project, insurance waived'),
    
    -- Miami Rentals
    (63, '2024-01-10', '2024-01-24', '2024-01-26', 8400.00, 2100.00, TRUE, 'Completed', 26, 4, 4, TRUE, 'SBC-240110', 'South Beach hotel renovation, returned late'),
    (64, '2024-02-01', '2024-02-29', '2024-02-28', 13200.00, 3300.00, TRUE, 'Completed', 28, 4, 4, TRUE, 'MWD-240201', 'Waterfront condominium development'),
    (65, '2024-03-01', '2024-03-15', NULL, 7600.00, 1900.00, FALSE, 'Active', 26, 4, 4, TRUE, 'BBG-240301', 'Brickell high-rise equipment'),
    (67, '2024-03-05', '2024-03-19', NULL, 6400.00, 1600.00, FALSE, 'Active', 28, 4, 4, TRUE, 'CGD-240305', 'Coconut Grove marina project'),
    (70, '2024-02-15', '2024-02-22', '2024-02-22', 3800.00, 950.00, TRUE, 'Completed', 26, 4, 4, TRUE, 'MDI-240215', 'Infrastructure upgrade project'),
    (68, '2024-03-10', '2024-04-10', NULL, 12000.00, 3000.00, FALSE, 'Active', 28, 4, 4, TRUE, 'PMC-240310', 'Port expansion monthly rental'),
    (69, '2024-03-08', '2024-03-15', NULL, 3200.00, 800.00, FALSE, 'Active', 26, 4, 4, TRUE, 'WUB-240308', 'Wynwood art district renovation'),
    
    -- Denver Rentals
    (83, '2024-01-15', '2024-01-29', '2024-01-28', 7200.00, 1800.00, TRUE, 'Completed', 32, 5, 5, TRUE, 'RMD-240115', 'Mountain residential development'),
    (84, '2024-02-01', '2024-02-15', '2024-02-16', 8400.00, 2100.00, TRUE, 'Completed', 33, 5, 5, TRUE, 'MHC-240201', 'Highway expansion project, returned late'),
    (85, '2024-03-01', '2024-03-08', NULL, 3600.00, 900.00, FALSE, 'Active', 32, 5, 5, TRUE, 'FRB-240301', 'Commercial building renovation'),
    (86, '2024-03-05', '2024-03-12', NULL, 3800.00, 950.00, FALSE, 'Active', 33, 5, 5, TRUE, 'CIS-240305', 'Industrial facility upgrade'),
    (88, '2024-02-20', '2024-03-20', '2024-03-18', 11500.00, 2800.00, FALSE, 'Completed', 32, 5, 5, TRUE, 'DMP-240220', 'Municipal project, returned early'),
    
    -- Atlanta Rentals
    (103, '2024-01-20', '2024-02-03', '2024-02-03', 7600.00, 1900.00, TRUE, 'Completed', 37, 6, 6, TRUE, 'PCG-240120', 'Commercial office renovation'),
    (104, '2024-02-10', '2024-02-24', '2024-02-25', 8800.00, 2200.00, TRUE, 'Completed', 39, 6, 6, TRUE, 'AMB-240210', 'Metropolitan transit expansion'),
    (105, '2024-03-01', '2024-03-15', NULL, 7200.00, 1800.00, FALSE, 'Active', 37, 6, 6, TRUE, 'GID-240301', 'Industrial park development'),
    (106, '2024-03-08', '2024-03-22', NULL, 6400.00, 1600.00, FALSE, 'Active', 39, 6, 6, TRUE, 'BCC-240308', 'Buckhead commercial center'),
    (108, '2024-02-15', '2024-03-15', '2024-03-14', 13500.00, 3375.00, TRUE, 'Completed', 37, 6, 6, TRUE, 'HAC-240215', 'Airport construction project');

-- Now let's insert rental_items that link rentals to specific equipment
INSERT INTO rental_items (rental_id, equipment_id, hourly_usage, daily_rate, quantity, start_condition, end_condition, damages_reported, damage_description, damage_charges)
VALUES
    -- Seattle Rental Items
    (1, 1, 40, 450.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (1, 14, 32, 225.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (2, 2, 120, 475.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (2, 5, 95, 550.00, 1, 'Excellent condition', 'Fair condition', TRUE, 'Minor hydraulic leak', 350.00),
    (3, 3, NULL, 350.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (3, 25, NULL, 280.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (4, 4, NULL, 485.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (5, 6, NULL, 525.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (6, 13, NULL, 220.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (7, 37, NULL, 175.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (7, 38, NULL, 300.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (8, 25, NULL, 280.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (8, 26, NULL, 260.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (9, 7, 75, 515.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (9, 41, 60, 205.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (10, 9, NULL, 650.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (11, 49, 40, 350.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    
    -- Houston Rental Items
    (12, 10, 150, 675.00, 1, 'Excellent condition', 'Fair condition', TRUE, 'Track damage', 750.00),
    (12, 16, 120, 230.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (13, 11, 85, 600.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (13, 19, 45, 325.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (14, 12, NULL, 625.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (14, 28, NULL, 175.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (15, 15, 75, 230.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (15, 31, 45, 345.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (16, 8, NULL, 525.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (16, 20, NULL, 340.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (17, 32, NULL, 330.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (17, 54, NULL, 365.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (18, 17, 60, 235.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (18, 42, 35, 205.00, 1, 'Excellent condition', 'Good condition', TRUE, 'Damaged tires', 150.00),
    (19, 18, NULL, 230.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (19, 22, NULL, 260.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (20, 44, NULL, 425.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (20, 56, NULL, 405.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    
    -- Chicago Rental Items
    (21, 23, 95, 340.00, 1, 'Good condition', 'Fair condition', TRUE, 'Hydraulic fluid leak', 250.00),
    (21, 39, 65, 195.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (21, 59, 80, 440.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (22, 24, 75, 330.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (22, 40, 35, 185.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (23, 21, NULL, 180.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (23, 27, NULL, 175.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (23, 43, NULL, 450.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (24, 29, NULL, 300.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (24, 47, NULL, 325.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (24, 55, NULL, 440.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (25, 30, 45, 245.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (25, 34, 30, 185.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (26, 35, NULL, 195.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (26, 51, NULL, 425.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (27, 36, NULL, 205.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (28, 45, 85, 115.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (28, 52, 60, 385.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    
    -- Miami Rental Items
    (29, 33, 65, 340.00, 1, 'Good condition', 'Fair condition', TRUE, 'Console damage', 200.00),
    (29, 46, 70, 275.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (30, 53, 120, 440.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (30, 57, 90, 425.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (31, 48, NULL, 350.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (31, 58, NULL, 365.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (32, 50, NULL, 225.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (32, 60, NULL, 385.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (33, 11, 55, 600.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (34, 12, NULL, 625.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (34, 28, NULL, 175.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (35, 15, NULL, 230.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    
    -- Denver Rental Items
    (36, 23, 85, 340.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (36, 39, 60, 195.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (37, 24, 80, 330.00, 1, 'Good condition', 'Fair condition', TRUE, 'Bucket damage', 350.00),
    (37, 40, 65, 185.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (38, 21, NULL, 180.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (38, 27, NULL, 175.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (39, 29, NULL, 300.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (39, 47, NULL, 325.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (40, 30, 110, 245.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (40, 34, 95, 185.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (40, 45, 85, 115.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    
    -- Atlanta Rental Items
    (41, 31, 70, 345.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (41, 43, 85, 450.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (42, 32, 95, 330.00, 1, 'Excellent condition', 'Fair condition', TRUE, 'Control panel damage', 275.00),
    (42, 44, 75, 425.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (43, 33, NULL, 340.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (43, 46, NULL, 275.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (44, 35, NULL, 195.00, 1, 'Good condition', NULL, FALSE, NULL, 0.00),
    (44, 51, NULL, 425.00, 1, 'Excellent condition', NULL, FALSE, NULL, 0.00),
    (45, 36, 120, 205.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00),
    (45, 52, 90, 385.00, 1, 'Excellent condition', 'Good condition', FALSE, NULL, 0.00),
    (45, 60, 80, 385.00, 1, 'Good condition', 'Good condition', FALSE, NULL, 0.00);
-- Insert data into payments table
INSERT INTO payments (rental_id, payment_date, amount, payment_method, transaction_reference, processed_by, is_refund, notes)
VALUES
    -- Seattle Payments
    (1, '2024-02-15', 3750.00, 'Credit Card', 'TXN-2402151342', 4, FALSE, 'Full payment at pickup'),
    (1, '2024-02-22', 1000.00, 'Credit Card', 'TXN-2402221555', 4, TRUE, 'Deposit refund on return'),
    (2, '2024-01-10', 6000.00, 'Bank Transfer', 'RDG-240110-BT', 4, FALSE, 'Initial payment - 50% of rental'),
    (2, '2024-01-20', 6600.00, 'Bank Transfer', 'RDG-240120-BT', 4, FALSE, 'Balance payment plus late fees'),
    (2, '2024-01-27', 2650.00, 'Bank Transfer', 'RDG-240127-BT', 4, TRUE, 'Deposit refund minus damage charges'),
    (3, '2024-02-25', 5950.00, 'Corporate Account', 'PSC-240225-CA', 2, FALSE, 'Charged to customer account'),
    (3, '2024-02-25', 1500.00, 'Corporate Account', 'PSC-240225-DEP', 2, FALSE, 'Security deposit'),
    (4, '2024-03-01', 9700.00, 'Bank Transfer', 'CIL-240301-BT', 4, FALSE, 'Full payment for monthly rental'),
    (4, '2024-03-01', 2500.00, 'Bank Transfer', 'CIL-240301-DEP', 4, FALSE, 'Security deposit'),
    (5, '2024-03-05', 4500.00, 'Credit Card', 'TXN-2403051021', 2, FALSE, 'Full payment at pickup'),
    (5, '2024-03-05', 1200.00, 'Credit Card', 'TXN-2403051022', 2, FALSE, 'Security deposit'),
    (6, '2024-03-15', 1350.00, 'Credit Card', 'TXN-2403150945', 4, FALSE, 'Full payment for weekend rental'),
    (6, '2024-03-15', 500.00, 'Credit Card', 'TXN-2403150946', 4, FALSE, 'Security deposit'),
    (7, '2024-03-20', 3600.00, 'Credit Card', 'TXN-2403201232', 2, FALSE, 'Full payment at pickup'),
    (7, '2024-03-20', 900.00, 'Credit Card', 'TXN-2403201233', 2, FALSE, 'Security deposit'),
    (8, '2024-03-10', 2450.00, 'Corporate Account', 'SES-240310-CA', 4, FALSE, 'Charged to customer account'),
    (8, '2024-03-10', 800.00, 'Corporate Account', 'SES-240310-DEP', 4, FALSE, 'Security deposit'),
    (9, '2024-02-01', 8400.00, 'Bank Transfer', 'OC-240201-BT', 2, FALSE, 'Full payment at pickup'),
    (9, '2024-02-14', 2000.00, 'Bank Transfer', 'OC-240214-RF', 2, TRUE, 'Full deposit refund - no damages'),
    (10, '2024-03-18', 5200.00, 'Government Purchase Order', 'SMP-240318-PO', 4, FALSE, 'Municipal project - PO payment'),
    (11, '2024-01-05', 2800.00, 'Credit Card', 'TXN-2401051109', 2, FALSE, 'Full payment at pickup'),
    (11, '2024-01-12', 700.00, 'Credit Card', 'TXN-2401121356', 2, TRUE, 'Full deposit refund - no damages'),
    
    -- Houston Payments
    (12, '2024-01-15', 7250.00, 'Corporate Account', 'TOFS-240115-CA', 13, FALSE, '50% payment at pickup'),
    (12, '2024-02-15', 7250.00, 'Corporate Account', 'TOFS-240215-CA', 13, FALSE, 'Balance payment'),
    (12, '2024-02-17', 2750.00, 'Corporate Account', 'TOFS-240217-RF', 13, TRUE, 'Partial deposit refund due to damage'),
    (13, '2024-02-10', 9200.00, 'Bank Transfer', 'WCDC-240210-BT', 11, FALSE, 'Full payment at pickup'),
    (13, '2024-02-24', 2300.00, 'Bank Transfer', 'WCDC-240224-RF', 11, TRUE, 'Full deposit refund - no damages'),
    (14, '2024-03-01', 11500.00, 'Credit Card', 'TXN-2403011432', 13, FALSE, 'Monthly rental payment'),
    (14, '2024-03-01', 2800.00, 'Credit Card', 'TXN-2403011433', 13, FALSE, 'Security deposit'),
    (15, '2024-02-20', 6800.00, 'Corporate Account', 'HMCD-240220-CA', 11, FALSE, 'Full payment at pickup'),
    (15, '2024-03-04', 1700.00, 'Corporate Account', 'HMCD-240304-RF', 11, TRUE, 'Full deposit refund - no damages'),
    (16, '2024-03-10', 8400.00, 'Bank Transfer', 'BCC-240310-BT', 13, FALSE, 'Full payment at pickup'),
    (16, '2024-03-10', 2100.00, 'Bank Transfer', 'BCC-240310-DEP', 13, FALSE, 'Security deposit'),
    (17, '2024-03-15', 6600.00, 'Credit Card', 'TXN-2403151545', 11, FALSE, '50% payment at pickup'),
    (17, '2024-03-15', 3300.00, 'Credit Card', 'TXN-2403151546', 11, FALSE, 'Security deposit'),
    (18, '2024-01-25', 3800.00, 'Credit Card', 'TXN-2401251032', 13, FALSE, 'Full payment at pickup'),
    (18, '2024-02-02', 800.00, 'Credit Card', 'TXN-2402021402', 13, TRUE, 'Partial deposit refund due to damage and late return'),
    (19, '2024-03-08', 3200.00, 'Credit Card', 'TXN-2403080942', 11, FALSE, 'Full payment at pickup'),
    (19, '2024-03-08', 800.00, 'Credit Card', 'TXN-2403080943', 11, FALSE, 'Security deposit'),
    (20, '2024-03-12', 7600.00, 'Bank Transfer', 'SLB-240312-BT', 13, FALSE, 'Full payment at pickup'),
    (20, '2024-03-12', 1900.00, 'Bank Transfer', 'SLB-240312-DEP', 13, FALSE, 'Security deposit'),
    
    -- Chicago Payments
    (21, '2024-01-20', 13800.00, 'Corporate Account', 'CRB-240120-CA', 21, FALSE, 'Full payment at pickup'),
    (21, '2024-02-18', 3250.00, 'Corporate Account', 'CRB-240218-RF', 21, TRUE, 'Partial deposit refund due to damage'),
    (22, '2024-02-05', 7200.00, 'Bank Transfer', 'NSC-240205-BT', 19, FALSE, 'Full payment at pickup'),
    (22, '2024-02-19', 1800.00, 'Bank Transfer', 'NSC-240219-RF', 19, TRUE, 'Full deposit refund - no damages'),
    (23, '2024-03-01', 8400.00, 'Credit Card', 'TXN-2403011232', 21, FALSE, 'Full payment at pickup'),
    (23, '2024-03-01', 2100.00, 'Credit Card', 'TXN-2403011233', 21, FALSE, 'Security deposit'),
    (24, '2024-03-05', 7800.00, 'Corporate Account', 'OEG-240305-CA1', 19, FALSE, '50% initial payment'),
    (24, '2024-03-05', 3900.00, 'Corporate Account', 'OEG-240305-DEP', 19, FALSE, 'Security deposit'),
    (24, '2024-03-20', 7800.00, 'Corporate Account', 'OEG-240320-CA2', 19, FALSE, '50% balance payment'),
    (25, '2024-02-15', 4200.00, 'Credit Card', 'TXN-2402151109', 21, FALSE, 'Full payment at pickup'),
    (25, '2024-02-23', 1050.00, 'Credit Card', 'TXN-2402231422', 21, TRUE, 'Full deposit refund - no damages'),
    (26, '2024-03-10', 8800.00, 'Bank Transfer', 'MMD-240310-BT', 19, FALSE, 'Full payment at pickup'),
    (26, '2024-03-10', 2200.00, 'Bank Transfer', 'MMD-240310-DEP', 19, FALSE, 'Security deposit'),
    (27, '2024-03-12', 4200.00, 'Credit Card', 'TXN-2403121542', 21, FALSE, 'Full payment at pickup'),
    (27, '2024-03-12', 1050.00, 'Credit Card', 'TXN-2403121543', 21, FALSE, 'Security deposit'),
    (28, '2024-01-15', 7600.00, 'Government Purchase Order', 'CMP-240115-PO', 19, FALSE, 'Municipal project - PO payment'),
    (28, '2024-01-29', 1900.00, 'Check', 'CMP-240129-DEP', 19, TRUE, 'Deposit refund by check'),
    
    -- Miami Payments
    (29, '2024-01-10', 8400.00, 'Corporate Account', 'SBC-240110-CA', 28, FALSE, 'Full payment at pickup'),
    (29, '2024-01-26', 1900.00, 'Corporate Account', 'SBC-240126-RF', 28, TRUE, 'Partial deposit refund due to damage'),
    (30, '2024-02-01', 6600.00, 'Bank Transfer', 'MWD-240201-BT1', 26, FALSE, '50% initial payment'),
    (30, '2024-02-15', 6600.00, 'Bank Transfer', 'MWD-240215-BT2', 26, FALSE, '50% balance payment'),
    (30, '2024-02-28', 3300.00, 'Bank Transfer', 'MWD-240228-RF', 26, TRUE, 'Full deposit refund - no damages'),
    (31, '2024-03-01', 7600.00, 'Credit Card', 'TXN-2403011011', 28, FALSE, 'Full payment at pickup'),
    (31, '2024-03-01', 1900.00, 'Credit Card', 'TXN-2403011012', 28, FALSE, 'Security deposit'),
    (32, '2024-03-05', 6400.00, 'Corporate Account', 'CGD-240305-CA', 26, FALSE, 'Full payment at pickup'),
    (32, '2024-03-05', 1600.00, 'Corporate Account', 'CGD-240305-DEP', 26, FALSE, 'Security deposit'),
    (33, '2024-02-15', 3800.00, 'Government Purchase Order', 'MDI-240215-PO', 28, FALSE, 'Infrastructure project - PO payment'),
    (33, '2024-02-22', 950.00, 'Check', 'MDI-240222-DEP', 28, TRUE, 'Deposit refund by check'),
    (34, '2024-03-10', 6000.00, 'Bank Transfer', 'PMC-240310-BT1', 26, FALSE, '50% initial payment'),
    (34, '2024-03-10', 3000.00, 'Bank Transfer', 'PMC-240310-DEP', 26, FALSE, 'Security deposit'),
    (35, '2024-03-08', 3200.00, 'Credit Card', 'TXN-2403080830', 28, FALSE, 'Full payment at pickup'),
    (35, '2024-03-08', 800.00, 'Credit Card', 'TXN-2403080831', 28, FALSE, 'Security deposit'),
    
    -- Denver Payments
    (36, '2024-01-15', 7200.00, 'Corporate Account', 'RMD-240115-CA', 33, FALSE, 'Full payment at pickup'),
    (36, '2024-01-28', 1800.00, 'Corporate Account', 'RMD-240128-RF', 33, TRUE, 'Full deposit refund - no damages'),
    (37, '2024-02-01', 8400.00, 'Bank Transfer', 'MHC-240201-BT', 32, FALSE, 'Full payment at pickup'),
    (37, '2024-02-16', 1750.00, 'Bank Transfer', 'MHC-240216-RF', 32, TRUE, 'Partial deposit refund due to damage'),
    (38, '2024-03-01', 3600.00, 'Credit Card', 'TXN-2403010924', 33, FALSE, 'Full payment at pickup'),
    (38, '2024-03-01', 900.00, 'Credit Card', 'TXN-2403010925', 33, FALSE, 'Security deposit'),
    (39, '2024-03-05', 3800.00, 'Credit Card', 'TXN-2403051310', 32, FALSE, 'Full payment at pickup'),
    (39, '2024-03-05', 950.00, 'Credit Card', 'TXN-2403051311', 32, FALSE, 'Security deposit'),
    (40, '2024-02-20', 11500.00, 'Government Purchase Order', 'DMP-240220-PO', 33, FALSE, 'Municipal project - PO payment'),
    
    -- Atlanta Payments
    (41, '2024-01-20', 7600.00, 'Corporate Account', 'PCG-240120-CA', 39, FALSE, 'Full payment at pickup'),
    (41, '2024-02-03', 1900.00, 'Corporate Account', 'PCG-240203-RF', 39, TRUE, 'Full deposit refund - no damages'),
    (42, '2024-02-10', 8800.00, 'Bank Transfer', 'AMB-240210-BT', 37, FALSE, 'Full payment at pickup'),
    (42, '2024-02-25', 1925.00, 'Bank Transfer', 'AMB-240225-RF', 37, TRUE, 'Partial deposit refund due to damage'),
    (43, '2024-03-01', 7200.00, 'Credit Card', 'TXN-2403011622', 39, FALSE, 'Full payment at pickup'),
    (43, '2024-03-01', 1800.00, 'Credit Card', 'TXN-2403011623', 39, FALSE, 'Security deposit'),
    (44, '2024-03-08', 6400.00, 'Corporate Account', 'BCC-240308-CA', 37, FALSE, 'Full payment at pickup'),
    (44, '2024-03-08', 1600.00, 'Corporate Account', 'BCC-240308-DEP', 37, FALSE, 'Security deposit'),
    (45, '2024-02-15', 13500.00, 'Government Purchase Order', 'HAC-240215-PO', 39, FALSE, 'Airport project - PO payment'),
    (45, '2024-03-14', 3375.00, 'Check', 'HAC-240314-RF', 39, TRUE, 'Full deposit refund - no damages');
-- Indexes for frequently used queries on the equipment table
CREATE INDEX idx_equipment_availability ON equipment(status);
CREATE INDEX idx_equipment_category_status ON equipment(category_id, status);
CREATE INDEX idx_equipment_location_status ON equipment(location_id, status);
CREATE INDEX idx_equipment_maintenance_date ON equipment(last_maintenance_date);
CREATE INDEX idx_equipment_rental_rates ON equipment(daily_rental_rate, weekly_rental_rate, monthly_rental_rate);
CREATE INDEX idx_equipment_condition ON equipment(condition_rating);

-- Indexes for customers table
CREATE INDEX idx_customer_location ON customers(city, state);
CREATE INDEX idx_customer_name ON customers(company_name);
CREATE INDEX idx_customer_contact ON customers(contact_person);
CREATE INDEX idx_customer_credit ON customers(credit_limit, is_active);

-- Indexes for rentals table
CREATE INDEX idx_rental_dates ON rentals(rental_date, expected_return_date, actual_return_date);
CREATE INDEX idx_rental_status_dates ON rentals(status, rental_date, expected_return_date);
CREATE INDEX idx_rental_customer_status ON rentals(customer_id, status);
CREATE INDEX idx_rental_location_dates ON rentals(pickup_location_id, rental_date);
CREATE INDEX idx_overdue_rentals ON rentals(expected_return_date)
    WHERE actual_return_date IS NULL AND status = 'Active';

-- Indexes for rental_items table
CREATE INDEX idx_rental_items_hourly_usage ON rental_items(hourly_usage);
CREATE INDEX idx_rental_items_damages ON rental_items(damages_reported);
CREATE INDEX idx_rental_item_equipment_rental ON rental_items(equipment_id, rental_id);

-- Indexes for maintenance_records table
CREATE INDEX idx_maintenance_type_date ON maintenance_records(maintenance_type, maintenance_date);
CREATE INDEX idx_maintenance_next_date ON maintenance_records(next_maintenance_date);
CREATE INDEX idx_maintenance_status ON maintenance_records(status);
CREATE INDEX idx_equipment_upcoming_maintenance ON maintenance_records(equipment_id, next_maintenance_date)
    WHERE status != 'Completed';

-- Indexes for payments table
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_method ON payments(payment_method);
CREATE INDEX idx_payments_refund ON payments(is_refund);
CREATE INDEX idx_payments_rental_date ON payments(rental_id, payment_date);

-- Indexes for employees table
CREATE INDEX idx_employee_position ON employees(position);
CREATE INDEX idx_employee_name ON employees(last_name, first_name);
CREATE INDEX idx_employee_certification ON employees USING GIN(certification);

-- Indexes for employee_locations table
CREATE INDEX idx_employee_location_dates ON employee_locations(start_date, end_date);
-- Modified to remove CURRENT_DATE which is not IMMUTABLE
CREATE INDEX idx_current_assignments ON employee_locations(employee_id, location_id, end_date);
