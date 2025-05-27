BEGIN;

CREATE TABLE alembic_version (
    version_num VARCHAR(32) NOT NULL,
    CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num)
);

-- Running upgrade  -> 3cd2245c7c00

CREATE TABLE aggregator (
    aggregator_id SERIAL NOT NULL,
    name VARCHAR NOT NULL,
    PRIMARY KEY (aggregator_id)
);

CREATE TABLE certificate (
    certificate_id SERIAL NOT NULL,
    created TIMESTAMP WITH TIME ZONE,
    lfdi VARCHAR(42) NOT NULL,
    expiry TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (certificate_id)
);

CREATE TABLE tariff (
    tariff_id SERIAL NOT NULL,
    name VARCHAR(64) NOT NULL,
    dnsp_code VARCHAR(20) NOT NULL,
    currency_code INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (tariff_id)
);

CREATE TABLE aggregator_certificate_assignment (
    assignment_id SERIAL NOT NULL,
    certificate_id INTEGER NOT NULL,
    aggregator_id INTEGER NOT NULL,
    PRIMARY KEY (assignment_id),
    FOREIGN KEY(aggregator_id) REFERENCES aggregator (aggregator_id),
    FOREIGN KEY(certificate_id) REFERENCES certificate (certificate_id)
);

CREATE TABLE site (
    site_id SERIAL NOT NULL,
    nmi VARCHAR(11),
    aggregator_id INTEGER NOT NULL,
    timezone_id VARCHAR(64) NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    lfdi VARCHAR(42) NOT NULL,
    sfdi BIGINT NOT NULL,
    device_category INTEGER NOT NULL,
    PRIMARY KEY (site_id),
    FOREIGN KEY(aggregator_id) REFERENCES aggregator (aggregator_id),
    UNIQUE (lfdi),
    CONSTRAINT lfdi_aggregator_id_uc UNIQUE (lfdi, aggregator_id),
    CONSTRAINT sfdi_aggregator_id_uc UNIQUE (sfdi, aggregator_id)
);

CREATE TABLE dynamic_operating_envelope (
    dynamic_operating_envelope_id SERIAL NOT NULL,
    site_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_seconds INTEGER NOT NULL,
    import_limit_active_watts DECIMAL(16, 2) NOT NULL,
    export_limit_watts DECIMAL(16, 2) NOT NULL,
    PRIMARY KEY (dynamic_operating_envelope_id),
    FOREIGN KEY(site_id) REFERENCES site (site_id),
    CONSTRAINT site_id_start_time_uc UNIQUE (site_id, start_time)
);

CREATE TABLE site_reading_type (
    site_reading_type_id SERIAL NOT NULL,
    aggregator_id INTEGER NOT NULL,
    site_id INTEGER NOT NULL,
    uom INTEGER NOT NULL,
    data_qualifier INTEGER NOT NULL,
    flow_direction INTEGER NOT NULL,
    accumulation_behaviour INTEGER NOT NULL,
    kind INTEGER NOT NULL,
    phase INTEGER NOT NULL,
    power_of_ten_multiplier INTEGER NOT NULL,
    default_interval_seconds INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (site_reading_type_id),
    FOREIGN KEY(aggregator_id) REFERENCES aggregator (aggregator_id),
    FOREIGN KEY(site_id) REFERENCES site (site_id),
    CONSTRAINT site_reading_type_all_values_uc UNIQUE (aggregator_id, site_id, uom, data_qualifier, flow_direction, accumulation_behaviour, kind, phase, power_of_ten_multiplier, default_interval_seconds)
);

CREATE TABLE tariff_generated_rate (
    tariff_generated_rate_id SERIAL NOT NULL,
    tariff_id INTEGER NOT NULL,
    site_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_seconds INTEGER NOT NULL,
    import_active_price DECIMAL(10, 4) NOT NULL,
    export_active_price DECIMAL(10, 4) NOT NULL,
    import_reactive_price DECIMAL(10, 4) NOT NULL,
    export_reactive_price DECIMAL(10, 4) NOT NULL,
    PRIMARY KEY (tariff_generated_rate_id),
    FOREIGN KEY(site_id) REFERENCES site (site_id),
    FOREIGN KEY(tariff_id) REFERENCES tariff (tariff_id),
    CONSTRAINT tariff_id_site_id_start_time_uc UNIQUE (tariff_id, site_id, start_time)
);

CREATE TABLE site_reading (
    site_reading_id SERIAL NOT NULL,
    site_reading_type_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    local_id INTEGER,
    quality_flags INTEGER NOT NULL,
    time_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    time_period_seconds INTEGER NOT NULL,
    value INTEGER NOT NULL,
    PRIMARY KEY (site_reading_id),
    FOREIGN KEY(site_reading_type_id) REFERENCES site_reading_type (site_reading_type_id),
    CONSTRAINT site_reading_type_id_time_period_start_uc UNIQUE (site_reading_type_id, time_period_start)
);

INSERT INTO alembic_version (version_num) VALUES ('3cd2245c7c00') RETURNING alembic_version.version_num;

-- Running upgrade 3cd2245c7c00 -> a0b35d4fff6c

CREATE TABLE aggregator_domain (
    aggregator_domain_id SERIAL NOT NULL,
    aggregator_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    domain VARCHAR(512) NOT NULL,
    PRIMARY KEY (aggregator_domain_id),
    FOREIGN KEY(aggregator_id) REFERENCES aggregator (aggregator_id) ON DELETE CASCADE
);

CREATE TABLE subscription (
    subscription_id SERIAL NOT NULL,
    aggregator_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    resource_type INTEGER NOT NULL,
    resource_id INTEGER,
    scoped_site_id INTEGER,
    notification_uri VARCHAR(2048) NOT NULL,
    entity_limit INTEGER NOT NULL,
    PRIMARY KEY (subscription_id),
    FOREIGN KEY(aggregator_id) REFERENCES aggregator (aggregator_id),
    FOREIGN KEY(scoped_site_id) REFERENCES site (site_id)
);

CREATE INDEX aggregator_id ON subscription (resource_type);

CREATE TABLE subscription_condition (
    subscription_condition_id SERIAL NOT NULL,
    subscription_id INTEGER NOT NULL,
    attribute INTEGER NOT NULL,
    lower_threshold INTEGER,
    upper_threshold INTEGER,
    PRIMARY KEY (subscription_condition_id),
    FOREIGN KEY(subscription_id) REFERENCES subscription (subscription_id) ON DELETE CASCADE
);

CREATE INDEX ix_dynamic_operating_envelope_changed_time ON dynamic_operating_envelope (changed_time);

CREATE INDEX ix_site_changed_time ON site (changed_time);

CREATE INDEX ix_site_reading_changed_time ON site_reading (changed_time);

CREATE INDEX ix_tariff_generated_rate_changed_time ON tariff_generated_rate (changed_time);

UPDATE alembic_version SET version_num='a0b35d4fff6c' WHERE alembic_version.version_num = '3cd2245c7c00';

-- Running upgrade a0b35d4fff6c -> 28d4321746ee

CREATE TABLE site_group (
    site_group_id SERIAL NOT NULL,
    name VARCHAR(128) NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (site_group_id),
    CONSTRAINT name_uc UNIQUE (name)
);

CREATE TABLE site_group_assignment (
    site_group_assignment_id SERIAL NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    site_id INTEGER NOT NULL,
    site_group_id INTEGER NOT NULL,
    PRIMARY KEY (site_group_assignment_id),
    FOREIGN KEY(site_group_id) REFERENCES site_group (site_group_id) ON DELETE CASCADE,
    FOREIGN KEY(site_id) REFERENCES site (site_id) ON DELETE CASCADE,
    CONSTRAINT site_id_site_group_id_uc UNIQUE (site_id, site_group_id)
);

UPDATE alembic_version SET version_num='28d4321746ee' WHERE alembic_version.version_num = 'a0b35d4fff6c';

-- Running upgrade 28d4321746ee -> 9edddd3c2d15

CREATE TABLE site_der (
    site_der_id SERIAL NOT NULL,
    site_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (site_der_id),
    FOREIGN KEY(site_id) REFERENCES site (site_id) ON DELETE CASCADE
);

CREATE INDEX ix_site_der_changed_time ON site_der (changed_time);

CREATE TABLE site_der_availability (
    site_der_availability_id SERIAL NOT NULL,
    site_der_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    availability_duration_sec INTEGER,
    max_charge_duration_sec INTEGER,
    reserved_charge_percent DECIMAL(8, 4),
    reserved_deliver_percent DECIMAL(8, 4),
    estimated_var_avail_value INTEGER,
    estimated_var_avail_multiplier INTEGER,
    estimated_w_avail_value INTEGER,
    estimated_w_avail_multiplier INTEGER,
    PRIMARY KEY (site_der_availability_id),
    FOREIGN KEY(site_der_id) REFERENCES site_der (site_der_id) ON DELETE CASCADE,
    UNIQUE (site_der_id)
);

CREATE INDEX ix_site_der_availability_changed_time ON site_der_availability (changed_time);

CREATE TABLE site_der_rating (
    site_der_rating_id SERIAL NOT NULL,
    site_der_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    modes_supported INTEGER,
    abnormal_category INTEGER,
    max_a_value INTEGER,
    max_a_multiplier INTEGER,
    max_ah_value INTEGER,
    max_ah_multiplier INTEGER,
    max_charge_rate_va_value INTEGER,
    max_charge_rate_va_multiplier INTEGER,
    max_charge_rate_w_value INTEGER,
    max_charge_rate_w_multiplier INTEGER,
    max_discharge_rate_va_value INTEGER,
    max_discharge_rate_va_multiplier INTEGER,
    max_discharge_rate_w_value INTEGER,
    max_discharge_rate_w_multiplier INTEGER,
    max_v_value INTEGER,
    max_v_multiplier INTEGER,
    max_va_value INTEGER,
    max_va_multiplier INTEGER,
    max_var_value INTEGER,
    max_var_multiplier INTEGER,
    max_var_neg_value INTEGER,
    max_var_neg_multiplier INTEGER,
    max_w_value INTEGER NOT NULL,
    max_w_multiplier INTEGER NOT NULL,
    max_wh_value INTEGER,
    max_wh_multiplier INTEGER,
    min_pf_over_excited_displacement INTEGER,
    min_pf_over_excited_multiplier INTEGER,
    min_pf_under_excited_displacement INTEGER,
    min_pf_under_excited_multiplier INTEGER,
    min_v_value INTEGER,
    min_v_multiplier INTEGER,
    normal_category INTEGER,
    over_excited_pf_displacement INTEGER,
    over_excited_pf_multiplier INTEGER,
    over_excited_w_value INTEGER,
    over_excited_w_multiplier INTEGER,
    reactive_susceptance_value INTEGER,
    reactive_susceptance_multiplier INTEGER,
    under_excited_pf_displacement INTEGER,
    under_excited_pf_multiplier INTEGER,
    under_excited_w_value INTEGER,
    under_excited_w_multiplier INTEGER,
    v_nom_value INTEGER,
    v_nom_multiplier INTEGER,
    der_type INTEGER NOT NULL,
    doe_modes_supported INTEGER,
    PRIMARY KEY (site_der_rating_id),
    FOREIGN KEY(site_der_id) REFERENCES site_der (site_der_id) ON DELETE CASCADE,
    UNIQUE (site_der_id)
);

CREATE INDEX ix_site_der_rating_changed_time ON site_der_rating (changed_time);

CREATE TABLE site_der_setting (
    site_der_setting_id SERIAL NOT NULL,
    site_der_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    modes_enabled INTEGER,
    es_delay INTEGER,
    es_high_freq INTEGER,
    es_high_volt INTEGER,
    es_low_freq INTEGER,
    es_low_volt INTEGER,
    es_ramp_tms INTEGER,
    es_random_delay INTEGER,
    grad_w INTEGER NOT NULL,
    max_a_value INTEGER,
    max_a_multiplier INTEGER,
    max_ah_value INTEGER,
    max_ah_multiplier INTEGER,
    max_charge_rate_va_value INTEGER,
    max_charge_rate_va_multiplier INTEGER,
    max_charge_rate_w_value INTEGER,
    max_charge_rate_w_multiplier INTEGER,
    max_discharge_rate_va_value INTEGER,
    max_discharge_rate_va_multiplier INTEGER,
    max_discharge_rate_w_value INTEGER,
    max_discharge_rate_w_multiplier INTEGER,
    max_v_value INTEGER,
    max_v_multiplier INTEGER,
    max_va_value INTEGER,
    max_va_multiplier INTEGER,
    max_var_value INTEGER,
    max_var_multiplier INTEGER,
    max_var_neg_value INTEGER,
    max_var_neg_multiplier INTEGER,
    max_w_value INTEGER NOT NULL,
    max_w_multiplier INTEGER NOT NULL,
    max_wh_value INTEGER,
    max_wh_multiplier INTEGER,
    min_pf_over_excited_displacement INTEGER,
    min_pf_over_excited_multiplier INTEGER,
    min_pf_under_excited_displacement INTEGER,
    min_pf_under_excited_multiplier INTEGER,
    min_v_value INTEGER,
    min_v_multiplier INTEGER,
    soft_grad_w INTEGER,
    v_nom_value INTEGER,
    v_nom_multiplier INTEGER,
    v_ref_value INTEGER,
    v_ref_multiplier INTEGER,
    v_ref_ofs_value INTEGER,
    v_ref_ofs_multiplier INTEGER,
    doe_modes_enabled INTEGER,
    PRIMARY KEY (site_der_setting_id),
    FOREIGN KEY(site_der_id) REFERENCES site_der (site_der_id) ON DELETE CASCADE,
    UNIQUE (site_der_id)
);

CREATE INDEX ix_site_der_setting_changed_time ON site_der_setting (changed_time);

CREATE TABLE site_der_status (
    site_der_status_id SERIAL NOT NULL,
    site_der_id INTEGER NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    alarm_status INTEGER,
    generator_connect_status INTEGER,
    generator_connect_status_time TIMESTAMP WITH TIME ZONE,
    inverter_status INTEGER,
    inverter_status_time TIMESTAMP WITH TIME ZONE,
    local_control_mode_status INTEGER,
    local_control_mode_status_time TIMESTAMP WITH TIME ZONE,
    manufacturer_status VARCHAR(6),
    manufacturer_status_time TIMESTAMP WITH TIME ZONE,
    operational_mode_status INTEGER,
    operational_mode_status_time TIMESTAMP WITH TIME ZONE,
    state_of_charge_status INTEGER,
    state_of_charge_status_time TIMESTAMP WITH TIME ZONE,
    storage_mode_status INTEGER,
    storage_mode_status_time TIMESTAMP WITH TIME ZONE,
    storage_connect_status INTEGER,
    storage_connect_status_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (site_der_status_id),
    FOREIGN KEY(site_der_id) REFERENCES site_der (site_der_id) ON DELETE CASCADE,
    UNIQUE (site_der_id)
);

CREATE INDEX ix_site_der_status_changed_time ON site_der_status (changed_time);

UPDATE alembic_version SET version_num='9edddd3c2d15' WHERE alembic_version.version_num = '28d4321746ee';

-- Running upgrade 9edddd3c2d15 -> 6fe657562691

ALTER TABLE site_reading ALTER COLUMN value TYPE BIGINT;

UPDATE alembic_version SET version_num='6fe657562691' WHERE alembic_version.version_num = '9edddd3c2d15';

-- Running upgrade 6fe657562691 -> faa734c2aa46

CREATE TABLE calculation_log (
    calculation_log_id SERIAL NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    calculation_interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    calculation_interval_duration_seconds INTEGER NOT NULL,
    topology_id VARCHAR(64),
    external_id VARCHAR(64),
    description VARCHAR(1024),
    power_forecast_creation_time TIMESTAMP WITH TIME ZONE,
    weather_forecast_creation_time TIMESTAMP WITH TIME ZONE,
    weather_forecast_location_id VARCHAR(128),
    PRIMARY KEY (calculation_log_id)
);

CREATE INDEX ix_calculation_log_calculation_interval_start ON calculation_log (calculation_interval_start);

CREATE TABLE weather_forecast_log (
    weather_forecast_log_id SERIAL NOT NULL,
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_duration_seconds INTEGER NOT NULL,
    air_temperature_degrees_c DECIMAL(5, 2),
    apparent_temperature_degrees_c DECIMAL(5, 2),
    dew_point_degrees_c DECIMAL(5, 2),
    humidity_percent DECIMAL(5, 2),
    cloud_cover_percent DECIMAL(5, 2),
    rain_probability_percent DECIMAL(5, 2),
    rain_mm DECIMAL(8, 2),
    rain_rate_mm DECIMAL(8, 2),
    global_horizontal_irradiance_watts_m2 DECIMAL(8, 2),
    wind_speed_50m_km_h DECIMAL(8, 2),
    calculation_log_id INTEGER NOT NULL,
    PRIMARY KEY (weather_forecast_log_id),
    FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id) ON DELETE CASCADE
);

CREATE TABLE power_flow_log (
    power_flow_log_id SERIAL NOT NULL,
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_duration_seconds INTEGER NOT NULL,
    external_device_id VARCHAR(64),
    site_id INTEGER,
    solve_name VARCHAR(16),
    pu_voltage_min DECIMAL(8, 6),
    pu_voltage_max DECIMAL(8, 6),
    pu_voltage DECIMAL(8, 6),
    thermal_max_percent DECIMAL(8, 4),
    calculation_log_id INTEGER NOT NULL,
    PRIMARY KEY (power_flow_log_id),
    FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id) ON DELETE CASCADE,
    FOREIGN KEY(site_id) REFERENCES site (site_id)
);

CREATE TABLE power_forecast_log (
    power_forecast_log_id SERIAL NOT NULL,
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_duration_seconds INTEGER NOT NULL,
    external_device_id VARCHAR(64),
    site_id INTEGER,
    active_power_watts INTEGER,
    reactive_power_var INTEGER,
    calculation_log_id INTEGER NOT NULL,
    PRIMARY KEY (power_forecast_log_id),
    FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id) ON DELETE CASCADE,
    FOREIGN KEY(site_id) REFERENCES site (site_id)
);

CREATE TABLE power_target_log (
    power_target_log_id SERIAL NOT NULL,
    interval_start TIMESTAMP WITH TIME ZONE NOT NULL,
    interval_duration_seconds INTEGER NOT NULL,
    external_device_id VARCHAR(64),
    site_id INTEGER,
    target_active_power_watts INTEGER,
    target_reactive_power_var INTEGER,
    calculation_log_id INTEGER NOT NULL,
    PRIMARY KEY (power_target_log_id),
    FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id) ON DELETE CASCADE,
    FOREIGN KEY(site_id) REFERENCES site (site_id)
);

UPDATE alembic_version SET version_num='faa734c2aa46' WHERE alembic_version.version_num = '6fe657562691';

-- Running upgrade faa734c2aa46 -> f18fbf983ca9

CREATE TABLE calculation_log_variable_metadata (
    calculation_log_id INTEGER NOT NULL,
    variable_id INTEGER NOT NULL,
    name VARCHAR(64) NOT NULL,
    description VARCHAR(512) NOT NULL,
    PRIMARY KEY (calculation_log_id, variable_id),
    FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id) ON DELETE CASCADE
);

CREATE TABLE calculation_log_variable_value (
    calculation_log_id INTEGER NOT NULL,
    variable_id INTEGER NOT NULL,
    site_id_snapshot INTEGER NOT NULL,
    interval_period INTEGER NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    PRIMARY KEY (calculation_log_id, variable_id, site_id_snapshot, interval_period),
    FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id) ON DELETE CASCADE
);

DROP TABLE power_flow_log;

DROP TABLE power_forecast_log;

DROP TABLE power_target_log;

DROP TABLE weather_forecast_log;

DROP INDEX ix_calculation_log_calculation_interval_start;

ALTER TABLE calculation_log RENAME calculation_interval_start TO calculation_range_start;

ALTER TABLE calculation_log RENAME calculation_interval_duration_seconds TO calculation_range_duration_seconds;

CREATE INDEX ix_calculation_log_calculation_range_start ON calculation_log (calculation_range_start);

ALTER TABLE calculation_log ADD COLUMN interval_width_seconds INTEGER DEFAULT '300' NOT NULL;

ALTER TABLE calculation_log ALTER COLUMN interval_width_seconds DROP DEFAULT;

ALTER TABLE calculation_log ADD COLUMN power_forecast_basis_time TIMESTAMP WITH TIME ZONE;

ALTER TABLE certificate ALTER COLUMN created SET NOT NULL;

ALTER TABLE dynamic_operating_envelope ADD COLUMN calculation_log_id INTEGER;

ALTER TABLE dynamic_operating_envelope ADD FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id);

CREATE INDEX ix_dynamic_operating_envelope_calculation_log_id ON dynamic_operating_envelope (calculation_log_id);

ALTER TABLE subscription_condition ALTER COLUMN lower_threshold SET NOT NULL;

ALTER TABLE subscription_condition ALTER COLUMN upper_threshold SET NOT NULL;

ALTER TABLE tariff_generated_rate ADD COLUMN calculation_log_id INTEGER;

ALTER TABLE tariff_generated_rate ADD FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id);

CREATE INDEX ix_tariff_generated_rate_calculation_log_id ON tariff_generated_rate (calculation_log_id);

UPDATE alembic_version SET version_num='f18fbf983ca9' WHERE alembic_version.version_num = 'faa734c2aa46';

-- Running upgrade f18fbf983ca9 -> 22491fcef4fd

ALTER TABLE aggregator ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE aggregator ADD COLUMN changed_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE aggregator_domain ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE dynamic_operating_envelope ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site_der ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site_der_availability ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site_der_rating ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site_der_setting ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site_der_status ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site_group ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site_group_assignment ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site_reading ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE site_reading_type ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE subscription ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE tariff ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE tariff_generated_rate ADD COLUMN created_time TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL;

ALTER TABLE aggregator ALTER COLUMN changed_time DROP DEFAULT;

UPDATE aggregator_domain SET created_time = changed_time;

UPDATE dynamic_operating_envelope SET created_time = changed_time;

UPDATE site SET created_time = changed_time;

UPDATE site_der SET created_time = changed_time;

UPDATE site_der_availability SET created_time = changed_time;

UPDATE site_der_rating SET created_time = changed_time;

UPDATE site_der_setting SET created_time = changed_time;

UPDATE site_der_status SET created_time = changed_time;

UPDATE site_group SET created_time = changed_time;

UPDATE site_group_assignment SET created_time = changed_time;

UPDATE site_reading SET created_time = changed_time;

UPDATE site_reading_type SET created_time = changed_time;

UPDATE subscription SET created_time = changed_time;

UPDATE tariff SET created_time = changed_time;

UPDATE tariff_generated_rate SET created_time = changed_time;

UPDATE alembic_version SET version_num='22491fcef4fd' WHERE alembic_version.version_num = 'f18fbf983ca9';

-- Running upgrade 22491fcef4fd -> 12e31583384d

ALTER TABLE dynamic_operating_envelope ALTER COLUMN dynamic_operating_envelope_id TYPE BIGINT;

ALTER TABLE site_reading ALTER COLUMN site_reading_id TYPE BIGINT;

ALTER TABLE tariff_generated_rate ALTER COLUMN tariff_generated_rate_id TYPE BIGINT;

ALTER SEQUENCE dynamic_operating_envelope_dynamic_operating_envelope_id_seq AS BIGINT MAXVALUE 9223372036854775807;

ALTER SEQUENCE site_reading_site_reading_id_seq AS BIGINT MAXVALUE 9223372036854775807;

ALTER SEQUENCE tariff_generated_rate_tariff_generated_rate_id_seq AS BIGINT MAXVALUE 9223372036854775807;

UPDATE alembic_version SET version_num='12e31583384d' WHERE alembic_version.version_num = '22491fcef4fd';

-- Running upgrade 12e31583384d -> e42aa138c308

CREATE TABLE archive_dynamic_operating_envelope (
    dynamic_operating_envelope_id BIGINT NOT NULL,
    site_id INTEGER NOT NULL,
    calculation_log_id INTEGER,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_seconds INTEGER NOT NULL,
    import_limit_active_watts DECIMAL(16, 2) NOT NULL,
    export_limit_watts DECIMAL(16, 2) NOT NULL,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_dynamic_operating_envelope_deleted_time ON archive_dynamic_operating_envelope (deleted_time);

CREATE INDEX ix_archive_dynamic_operating_envelope_dynamic_operating_6d99 ON archive_dynamic_operating_envelope (dynamic_operating_envelope_id);

CREATE TABLE archive_site (
    site_id INTEGER NOT NULL,
    nmi VARCHAR(11),
    aggregator_id INTEGER NOT NULL,
    timezone_id VARCHAR(64) NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    lfdi VARCHAR(42) NOT NULL,
    sfdi BIGINT NOT NULL,
    device_category INTEGER NOT NULL,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_site_deleted_time ON archive_site (deleted_time);

CREATE INDEX ix_archive_site_site_id ON archive_site (site_id);

CREATE TABLE archive_site_der (
    site_der_id INTEGER NOT NULL,
    site_id INTEGER NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_site_der_deleted_time ON archive_site_der (deleted_time);

CREATE INDEX ix_archive_site_der_site_der_id ON archive_site_der (site_der_id);

CREATE TABLE archive_site_der_availability (
    site_der_availability_id INTEGER NOT NULL,
    site_der_id INTEGER NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    availability_duration_sec INTEGER,
    max_charge_duration_sec INTEGER,
    reserved_charge_percent DECIMAL(8, 4),
    reserved_deliver_percent DECIMAL(8, 4),
    estimated_var_avail_value INTEGER,
    estimated_var_avail_multiplier INTEGER,
    estimated_w_avail_value INTEGER,
    estimated_w_avail_multiplier INTEGER,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_site_der_availability_deleted_time ON archive_site_der_availability (deleted_time);

CREATE INDEX ix_archive_site_der_availability_site_der_availability_id ON archive_site_der_availability (site_der_availability_id);

CREATE TABLE archive_site_der_rating (
    site_der_rating_id INTEGER NOT NULL,
    site_der_id INTEGER NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    modes_supported INTEGER,
    abnormal_category INTEGER,
    max_a_value INTEGER,
    max_a_multiplier INTEGER,
    max_ah_value INTEGER,
    max_ah_multiplier INTEGER,
    max_charge_rate_va_value INTEGER,
    max_charge_rate_va_multiplier INTEGER,
    max_charge_rate_w_value INTEGER,
    max_charge_rate_w_multiplier INTEGER,
    max_discharge_rate_va_value INTEGER,
    max_discharge_rate_va_multiplier INTEGER,
    max_discharge_rate_w_value INTEGER,
    max_discharge_rate_w_multiplier INTEGER,
    max_v_value INTEGER,
    max_v_multiplier INTEGER,
    max_va_value INTEGER,
    max_va_multiplier INTEGER,
    max_var_value INTEGER,
    max_var_multiplier INTEGER,
    max_var_neg_value INTEGER,
    max_var_neg_multiplier INTEGER,
    max_w_value INTEGER NOT NULL,
    max_w_multiplier INTEGER NOT NULL,
    max_wh_value INTEGER,
    max_wh_multiplier INTEGER,
    min_pf_over_excited_displacement INTEGER,
    min_pf_over_excited_multiplier INTEGER,
    min_pf_under_excited_displacement INTEGER,
    min_pf_under_excited_multiplier INTEGER,
    min_v_value INTEGER,
    min_v_multiplier INTEGER,
    normal_category INTEGER,
    over_excited_pf_displacement INTEGER,
    over_excited_pf_multiplier INTEGER,
    over_excited_w_value INTEGER,
    over_excited_w_multiplier INTEGER,
    reactive_susceptance_value INTEGER,
    reactive_susceptance_multiplier INTEGER,
    under_excited_pf_displacement INTEGER,
    under_excited_pf_multiplier INTEGER,
    under_excited_w_value INTEGER,
    under_excited_w_multiplier INTEGER,
    v_nom_value INTEGER,
    v_nom_multiplier INTEGER,
    der_type INTEGER NOT NULL,
    doe_modes_supported INTEGER,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_site_der_rating_deleted_time ON archive_site_der_rating (deleted_time);

CREATE INDEX ix_archive_site_der_rating_site_der_rating_id ON archive_site_der_rating (site_der_rating_id);

CREATE TABLE archive_site_der_setting (
    site_der_setting_id INTEGER NOT NULL,
    site_der_id INTEGER NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    modes_enabled INTEGER,
    es_delay INTEGER,
    es_high_freq INTEGER,
    es_high_volt INTEGER,
    es_low_freq INTEGER,
    es_low_volt INTEGER,
    es_ramp_tms INTEGER,
    es_random_delay INTEGER,
    grad_w INTEGER NOT NULL,
    max_a_value INTEGER,
    max_a_multiplier INTEGER,
    max_ah_value INTEGER,
    max_ah_multiplier INTEGER,
    max_charge_rate_va_value INTEGER,
    max_charge_rate_va_multiplier INTEGER,
    max_charge_rate_w_value INTEGER,
    max_charge_rate_w_multiplier INTEGER,
    max_discharge_rate_va_value INTEGER,
    max_discharge_rate_va_multiplier INTEGER,
    max_discharge_rate_w_value INTEGER,
    max_discharge_rate_w_multiplier INTEGER,
    max_v_value INTEGER,
    max_v_multiplier INTEGER,
    max_va_value INTEGER,
    max_va_multiplier INTEGER,
    max_var_value INTEGER,
    max_var_multiplier INTEGER,
    max_var_neg_value INTEGER,
    max_var_neg_multiplier INTEGER,
    max_w_value INTEGER NOT NULL,
    max_w_multiplier INTEGER NOT NULL,
    max_wh_value INTEGER,
    max_wh_multiplier INTEGER,
    min_pf_over_excited_displacement INTEGER,
    min_pf_over_excited_multiplier INTEGER,
    min_pf_under_excited_displacement INTEGER,
    min_pf_under_excited_multiplier INTEGER,
    min_v_value INTEGER,
    min_v_multiplier INTEGER,
    soft_grad_w INTEGER,
    v_nom_value INTEGER,
    v_nom_multiplier INTEGER,
    v_ref_value INTEGER,
    v_ref_multiplier INTEGER,
    v_ref_ofs_value INTEGER,
    v_ref_ofs_multiplier INTEGER,
    doe_modes_enabled INTEGER,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_site_der_setting_deleted_time ON archive_site_der_setting (deleted_time);

CREATE INDEX ix_archive_site_der_setting_site_der_setting_id ON archive_site_der_setting (site_der_setting_id);

CREATE TABLE archive_site_der_status (
    site_der_status_id INTEGER NOT NULL,
    site_der_id INTEGER NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    alarm_status INTEGER,
    generator_connect_status INTEGER,
    generator_connect_status_time TIMESTAMP WITH TIME ZONE,
    inverter_status INTEGER,
    inverter_status_time TIMESTAMP WITH TIME ZONE,
    local_control_mode_status INTEGER,
    local_control_mode_status_time TIMESTAMP WITH TIME ZONE,
    manufacturer_status VARCHAR(6),
    manufacturer_status_time TIMESTAMP WITH TIME ZONE,
    operational_mode_status INTEGER,
    operational_mode_status_time TIMESTAMP WITH TIME ZONE,
    state_of_charge_status INTEGER,
    state_of_charge_status_time TIMESTAMP WITH TIME ZONE,
    storage_mode_status INTEGER,
    storage_mode_status_time TIMESTAMP WITH TIME ZONE,
    storage_connect_status INTEGER,
    storage_connect_status_time TIMESTAMP WITH TIME ZONE,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_site_der_status_deleted_time ON archive_site_der_status (deleted_time);

CREATE INDEX ix_archive_site_der_status_site_der_status_id ON archive_site_der_status (site_der_status_id);

CREATE TABLE archive_site_reading (
    site_reading_id BIGINT NOT NULL,
    site_reading_type_id INTEGER NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    local_id INTEGER,
    quality_flags INTEGER NOT NULL,
    time_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    time_period_seconds INTEGER NOT NULL,
    value BIGINT NOT NULL,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_site_reading_deleted_time ON archive_site_reading (deleted_time);

CREATE INDEX ix_archive_site_reading_site_reading_id ON archive_site_reading (site_reading_id);

CREATE TABLE archive_site_reading_type (
    site_reading_type_id INTEGER NOT NULL,
    aggregator_id INTEGER NOT NULL,
    site_id INTEGER NOT NULL,
    uom INTEGER NOT NULL,
    data_qualifier INTEGER NOT NULL,
    flow_direction INTEGER NOT NULL,
    accumulation_behaviour INTEGER NOT NULL,
    kind INTEGER NOT NULL,
    phase INTEGER NOT NULL,
    power_of_ten_multiplier INTEGER NOT NULL,
    default_interval_seconds INTEGER NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_site_reading_type_deleted_time ON archive_site_reading_type (deleted_time);

CREATE INDEX ix_archive_site_reading_type_site_reading_type_id ON archive_site_reading_type (site_reading_type_id);

CREATE TABLE archive_subscription (
    subscription_id INTEGER NOT NULL,
    aggregator_id INTEGER NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    resource_type INTEGER NOT NULL,
    resource_id INTEGER,
    scoped_site_id INTEGER,
    notification_uri VARCHAR(2048) NOT NULL,
    entity_limit INTEGER NOT NULL,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_subscription_deleted_time ON archive_subscription (deleted_time);

CREATE INDEX ix_archive_subscription_subscription_id ON archive_subscription (subscription_id);

CREATE TABLE archive_subscription_condition (
    subscription_condition_id INTEGER NOT NULL,
    subscription_id INTEGER NOT NULL,
    attribute INTEGER NOT NULL,
    lower_threshold INTEGER NOT NULL,
    upper_threshold INTEGER NOT NULL,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_subscription_condition_deleted_time ON archive_subscription_condition (deleted_time);

CREATE INDEX ix_archive_subscription_condition_subscription_condition_id ON archive_subscription_condition (subscription_condition_id);

CREATE TABLE archive_tariff (
    tariff_id INTEGER NOT NULL,
    name VARCHAR(64) NOT NULL,
    dnsp_code VARCHAR(20) NOT NULL,
    currency_code INTEGER NOT NULL,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_tariff_deleted_time ON archive_tariff (deleted_time);

CREATE INDEX ix_archive_tariff_tariff_id ON archive_tariff (tariff_id);

CREATE TABLE archive_tariff_generated_rate (
    tariff_generated_rate_id BIGINT NOT NULL,
    tariff_id INTEGER NOT NULL,
    site_id INTEGER NOT NULL,
    calculation_log_id INTEGER,
    created_time TIMESTAMP WITH TIME ZONE NOT NULL,
    changed_time TIMESTAMP WITH TIME ZONE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_seconds INTEGER NOT NULL,
    import_active_price DECIMAL(10, 4) NOT NULL,
    export_active_price DECIMAL(10, 4) NOT NULL,
    import_reactive_price DECIMAL(10, 4) NOT NULL,
    export_reactive_price DECIMAL(10, 4) NOT NULL,
    archive_id SERIAL NOT NULL,
    archive_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_time TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (archive_id)
);

CREATE INDEX ix_archive_tariff_generated_rate_deleted_time ON archive_tariff_generated_rate (deleted_time);

CREATE INDEX ix_archive_tariff_generated_rate_tariff_generated_rate_id ON archive_tariff_generated_rate (tariff_generated_rate_id);

UPDATE alembic_version SET version_num='e42aa138c308' WHERE alembic_version.version_num = '12e31583384d';

-- Running upgrade e42aa138c308 -> a69678b58de7

CREATE TABLE calculation_log_label_metadata (
    calculation_log_id INTEGER NOT NULL,
    label_id INTEGER NOT NULL,
    name VARCHAR(64) NOT NULL,
    description VARCHAR(512) NOT NULL,
    PRIMARY KEY (calculation_log_id, label_id),
    FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id) ON DELETE CASCADE
);

CREATE TABLE calculation_log_label_value (
    calculation_log_id INTEGER NOT NULL,
    label_id INTEGER NOT NULL,
    site_id_snapshot INTEGER NOT NULL,
    label VARCHAR(64) NOT NULL,
    PRIMARY KEY (calculation_log_id, label_id, site_id_snapshot),
    FOREIGN KEY(calculation_log_id) REFERENCES calculation_log (calculation_log_id) ON DELETE CASCADE
);

UPDATE alembic_version SET version_num='a69678b58de7' WHERE alembic_version.version_num = 'e42aa138c308';

COMMIT;

