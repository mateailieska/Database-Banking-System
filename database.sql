-- COMPLETE POSTGRESQL DDL FOR BANK DATABASE
-- Aligned with the ER diagram as closely as possible.
-- Main correction from previous version:
-- telefon, email and adresa can belong to exactly ONE of: klient, vraboten, banka, filijala.
-- This matches the ER diagram where these tables have four possible owner FKs.
-- Indexes are intentionally NOT included here; create them after CSV import.

ROLLBACK;

DROP TABLE IF EXISTS
--     role_privilegii,
--     role_user,
--     privilegii,
--     role,
--     telefon,
--     email,
--     adresa,
--     rata_kredit,
--     transakcija,
--     nalog,
--     karticka,
--     tip_karticka,
--     depozit,
--     smetka,
--     potpisnik,
--     dogovor,
--     kredit,
--     tip_kredit,
--     usluga,
--     klient,
--     vraboten,
--     raboti_vo,
--     filijala,
--     bank_user,
--     kursna_lista,
--     valuta,
--     banka,
--     izvestuvanje
CASCADE;

-- =========================
-- BANKA
-- =========================
CREATE TABLE banka (
    banka_id SERIAL PRIMARY KEY,
    ime_na_banka VARCHAR(100) NOT NULL DEFAULT 'unknown_bank',
    edb VARCHAR(13) NOT NULL UNIQUE,
    datum_na_osnovanje DATE,

    CONSTRAINT chk_banka_edb_len CHECK (length(edb) = 13)
);

-- =========================
-- VALUTA
-- =========================
CREATE TABLE valuta (
    valuta_id SERIAL PRIMARY KEY,
    kod CHAR(3) NOT NULL UNIQUE,
    ime VARCHAR(100) NOT NULL,
    simbol VARCHAR(5)
);

-- =========================
-- KURSNA_LISTA
-- =========================
CREATE TABLE kursna_lista (
    kurs_id SERIAL PRIMARY KEY,
    datum DATE NOT NULL DEFAULT CURRENT_DATE,
    kupoven_kurs NUMERIC(10,4) NOT NULL,
    sreden_kurs NUMERIC(10,4) NOT NULL,
    prodazen_kurs NUMERIC(10,4) NOT NULL,
    valuta_od_id INT NOT NULL,
    valuta_do_id INT NOT NULL,

    CONSTRAINT fk_kurs_valuta_od FOREIGN KEY (valuta_od_id)
        REFERENCES valuta(valuta_id) ON DELETE RESTRICT,
    CONSTRAINT fk_kurs_valuta_do FOREIGN KEY (valuta_do_id)
        REFERENCES valuta(valuta_id) ON DELETE RESTRICT,

    CONSTRAINT uq_kurs UNIQUE (datum, valuta_od_id, valuta_do_id),
    CONSTRAINT chk_kurs_positive CHECK (kupoven_kurs > 0 AND sreden_kurs > 0 AND prodazen_kurs > 0),
    CONSTRAINT chk_kurs_order CHECK (kupoven_kurs <= sreden_kurs AND sreden_kurs <= prodazen_kurs),
    CONSTRAINT chk_kurs_diff_valuti CHECK (valuta_od_id <> valuta_do_id)
);

-- =========================
-- BANK_USER / ROLE / PRIVILEGII
-- =========================
CREATE TABLE bank_user (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AKTIVEN',

    CONSTRAINT chk_bank_user_status CHECK (status IN ('AKTIVEN', 'NEAKTIVEN'))
);

CREATE TABLE role (
    role_id SERIAL PRIMARY KEY,
    ime VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE privilegii (
    privilegija_id SERIAL PRIMARY KEY,
    privilegija VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE role_privilegii (
    role_id INT NOT NULL,
    privilegija_id INT NOT NULL,
    PRIMARY KEY (role_id, privilegija_id),

    CONSTRAINT fk_role_privilegii_role FOREIGN KEY (role_id)
        REFERENCES role(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_role_privilegii_privilegii FOREIGN KEY (privilegija_id)
        REFERENCES privilegii(privilegija_id) ON DELETE CASCADE
);

CREATE TABLE role_user (
    role_id INT NOT NULL,
    user_id INT NOT NULL,
    PRIMARY KEY (role_id, user_id),

    CONSTRAINT fk_role_user_role FOREIGN KEY (role_id)
        REFERENCES role(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_role_user_user FOREIGN KEY (user_id)
        REFERENCES bank_user(user_id) ON DELETE CASCADE
);

-- =========================
-- FILIJALA
-- =========================
CREATE TABLE filijala (
    filijala_id SERIAL PRIMARY KEY,
    ime VARCHAR(100) NOT NULL,
    banka_id INT NOT NULL,

    CONSTRAINT fk_filijala_banka FOREIGN KEY (banka_id)
        REFERENCES banka(banka_id) ON DELETE RESTRICT
);

-- =========================
-- VRABOTEN
-- =========================
CREATE TABLE vraboten (
    vraboten_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    ime VARCHAR(100) NOT NULL,
    prezime VARCHAR(100) NOT NULL,
    tatkovo_ime VARCHAR(100),
    datum_ragjanje DATE,
    embg CHAR(13) NOT NULL UNIQUE,

    CONSTRAINT fk_vraboten_user FOREIGN KEY (user_id)
        REFERENCES bank_user(user_id) ON DELETE RESTRICT,
    CONSTRAINT chk_vraboten_embg_len CHECK (length(embg) = 13)
);

-- Extra table kept from your model.
CREATE TABLE raboti_vo (
    vraboten_id INT NOT NULL,
    filijala_id INT NOT NULL,
    raboti_od DATE NOT NULL,
    raboti_do DATE,

    PRIMARY KEY (vraboten_id, filijala_id, raboti_od),

    CONSTRAINT fk_raboti_vo_vraboten FOREIGN KEY (vraboten_id)
        REFERENCES vraboten(vraboten_id) ON DELETE RESTRICT,
    CONSTRAINT fk_raboti_vo_filijala FOREIGN KEY (filijala_id)
        REFERENCES filijala(filijala_id) ON DELETE RESTRICT,
    CONSTRAINT chk_raboti_vo_dates CHECK (raboti_do IS NULL OR raboti_do > raboti_od)
);

-- =========================
-- KLIENT
-- =========================
CREATE TABLE klient (
    klient_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    ime VARCHAR(100) NOT NULL,
    prezime VARCHAR(100) NOT NULL,
    datum_ragjanje DATE NOT NULL,
    tatkovo_ime VARCHAR(100),
    embg CHAR(13) NOT NULL UNIQUE,

    CONSTRAINT fk_klient_user FOREIGN KEY (user_id)
        REFERENCES bank_user(user_id) ON DELETE RESTRICT,
    CONSTRAINT chk_klient_embg_len CHECK (length(embg) = 13)
);

-- =========================
-- IZVESTUVANJE
-- =========================
CREATE TABLE izvestuvanje (
    izvestuvanje_id SERIAL PRIMARY KEY,
    naslov VARCHAR(100) NOT NULL,
    poraka TEXT NOT NULL,
    datum_isprakjanje DATE NOT NULL DEFAULT CURRENT_DATE,
    klient_id INT NOT NULL,
    banka_id INT NOT NULL,

    CONSTRAINT fk_izvestuvanje_klient FOREIGN KEY (klient_id)
        REFERENCES klient(klient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_izvestuvanje_banka FOREIGN KEY (banka_id)
        REFERENCES banka(banka_id) ON DELETE RESTRICT
);

-- =========================
-- CONTACT TABLES FROM ER
-- Each row belongs to exactly one owner: klient OR vraboten OR banka OR filijala.
-- =========================
CREATE TABLE telefon (
    telefon_id SERIAL PRIMARY KEY,
    telefonski_broj VARCHAR(20) NOT NULL UNIQUE,
    tip_telefon VARCHAR(50),
    klient_id INT,
    vraboten_id INT,
    banka_id INT,
    filijala_id INT,

    CONSTRAINT fk_telefon_klient FOREIGN KEY (klient_id)
        REFERENCES klient(klient_id) ON DELETE CASCADE,
    CONSTRAINT fk_telefon_vraboten FOREIGN KEY (vraboten_id)
        REFERENCES vraboten(vraboten_id) ON DELETE CASCADE,
    CONSTRAINT fk_telefon_banka FOREIGN KEY (banka_id)
        REFERENCES banka(banka_id) ON DELETE CASCADE,
    CONSTRAINT fk_telefon_filijala FOREIGN KEY (filijala_id)
        REFERENCES filijala(filijala_id) ON DELETE CASCADE,

    CONSTRAINT chk_telefon_one_owner CHECK (
        (CASE WHEN klient_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN vraboten_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN banka_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN filijala_id IS NULL THEN 0 ELSE 1 END) = 1
    )
);

CREATE TABLE email (
    email_id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    tip_email VARCHAR(50),
    klient_id INT,
    vraboten_id INT,
    banka_id INT,
    filijala_id INT,

    CONSTRAINT fk_email_klient FOREIGN KEY (klient_id)
        REFERENCES klient(klient_id) ON DELETE CASCADE,
    CONSTRAINT fk_email_vraboten FOREIGN KEY (vraboten_id)
        REFERENCES vraboten(vraboten_id) ON DELETE CASCADE,
    CONSTRAINT fk_email_banka FOREIGN KEY (banka_id)
        REFERENCES banka(banka_id) ON DELETE CASCADE,
    CONSTRAINT fk_email_filijala FOREIGN KEY (filijala_id)
        REFERENCES filijala(filijala_id) ON DELETE CASCADE,

    CONSTRAINT chk_email_one_owner CHECK (
        (CASE WHEN klient_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN vraboten_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN banka_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN filijala_id IS NULL THEN 0 ELSE 1 END) = 1
    )
);

CREATE TABLE adresa (
    adresa_id SERIAL PRIMARY KEY,
    drzava VARCHAR(100) NOT NULL,
    grad VARCHAR(100) NOT NULL,
    opstina VARCHAR(100),
    naselba VARCHAR(100),
    ulica VARCHAR(150),
    broj VARCHAR(20),
    stanben_broj VARCHAR(20),
    tip_adresa VARCHAR(50),
    klient_id INT,
    vraboten_id INT,
    banka_id INT,
    filijala_id INT,

    CONSTRAINT fk_adresa_klient FOREIGN KEY (klient_id)
        REFERENCES klient(klient_id) ON DELETE CASCADE,
    CONSTRAINT fk_adresa_vraboten FOREIGN KEY (vraboten_id)
        REFERENCES vraboten(vraboten_id) ON DELETE CASCADE,
    CONSTRAINT fk_adresa_banka FOREIGN KEY (banka_id)
        REFERENCES banka(banka_id) ON DELETE CASCADE,
    CONSTRAINT fk_adresa_filijala FOREIGN KEY (filijala_id)
        REFERENCES filijala(filijala_id) ON DELETE CASCADE,

    CONSTRAINT chk_adresa_one_owner CHECK (
        (CASE WHEN klient_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN vraboten_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN banka_id IS NULL THEN 0 ELSE 1 END) +
        (CASE WHEN filijala_id IS NULL THEN 0 ELSE 1 END) = 1
    )
);

-- =========================
-- USLUGA
-- =========================
CREATE TABLE usluga (
    usluga_id SERIAL PRIMARY KEY,
    ime VARCHAR(100) NOT NULL,
    opis VARCHAR(255),
    datum_od DATE,
    datum_do DATE,
    tip_usluga VARCHAR(100),
    status VARCHAR(30) NOT NULL DEFAULT 'AKTIVNA',
    banka_id INT NOT NULL,
    filijala_id INT NOT NULL,

    CONSTRAINT fk_usluga_banka FOREIGN KEY (banka_id)
        REFERENCES banka(banka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_usluga_filijala FOREIGN KEY (filijala_id)
        REFERENCES filijala(filijala_id) ON DELETE RESTRICT,

    CONSTRAINT chk_usluga_dates CHECK (datum_do IS NULL OR datum_od IS NULL OR datum_do > datum_od),
    CONSTRAINT chk_usluga_status CHECK (status IN ('AKTIVNA', 'NEAKTIVNA'))
);

-- =========================
-- TIP_KREDIT / KREDIT
-- =========================
CREATE TABLE tip_kredit (
    tip_kredit_id SERIAL PRIMARY KEY,
    tip VARCHAR(100) NOT NULL UNIQUE,
    opis VARCHAR(255)
);

CREATE TABLE kredit (
    kredit_id SERIAL PRIMARY KEY,
    kamatna_stapka NUMERIC(5,2) NOT NULL,
    rok_otplata INT NOT NULL,
    iznos_kredit NUMERIC(15,2) NOT NULL,
    mesecna_rata NUMERIC(15,2) NOT NULL,
    tip_kredit_id INT NOT NULL,
    usluga_id INT NOT NULL,
    valuta_id INT NOT NULL,

    CONSTRAINT fk_kredit_tip FOREIGN KEY (tip_kredit_id)
        REFERENCES tip_kredit(tip_kredit_id) ON DELETE RESTRICT,
    CONSTRAINT fk_kredit_usluga FOREIGN KEY (usluga_id)
        REFERENCES usluga(usluga_id) ON DELETE RESTRICT,
    CONSTRAINT fk_kredit_valuta FOREIGN KEY (valuta_id)
        REFERENCES valuta(valuta_id) ON DELETE RESTRICT,

    CONSTRAINT chk_kredit_iznos CHECK (iznos_kredit >= 0),
    CONSTRAINT chk_kredit_rata CHECK (mesecna_rata >= 0),
    CONSTRAINT chk_kredit_kamata CHECK (kamatna_stapka >= 0),
    CONSTRAINT chk_kredit_rok CHECK (rok_otplata > 0)
);

-- =========================
-- DOGOVOR / POTPISNIK
-- =========================
CREATE TABLE dogovor (
    dogovor_id SERIAL PRIMARY KEY,
    naslov VARCHAR(255) NOT NULL,
    datum_kreiranje DATE NOT NULL DEFAULT CURRENT_DATE,
    datum_posledna_promena DATE,
    datum_potpisuvanje DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'KREIRAN',
    klient_id INT NOT NULL,
    banka_id INT NOT NULL,
    usluga_id INT NOT NULL,
    filijala_id INT,

    CONSTRAINT fk_dogovor_klient FOREIGN KEY (klient_id)
        REFERENCES klient(klient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_dogovor_banka FOREIGN KEY (banka_id)
        REFERENCES banka(banka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_dogovor_usluga FOREIGN KEY (usluga_id)
        REFERENCES usluga(usluga_id) ON DELETE RESTRICT,
    CONSTRAINT fk_dogovor_filijala FOREIGN KEY (filijala_id)
        REFERENCES filijala(filijala_id) ON DELETE RESTRICT,

    CONSTRAINT chk_dogovor_status CHECK (status IN ('KREIRAN', 'POTPISAN', 'OTKAZAN', 'ISTECEN')),
    CONSTRAINT chk_dogovor_dates CHECK (datum_potpisuvanje IS NULL OR datum_potpisuvanje >= datum_kreiranje)
);

CREATE TABLE potpisnik (
    potpisnik_id SERIAL PRIMARY KEY,
    datum_potpisuvanje DATE NOT NULL DEFAULT CURRENT_DATE,
    klient_id INT NOT NULL,
    dogovor_id INT NOT NULL,

    CONSTRAINT fk_potpisnik_klient FOREIGN KEY (klient_id)
        REFERENCES klient(klient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_potpisnik_dogovor FOREIGN KEY (dogovor_id)
        REFERENCES dogovor(dogovor_id) ON DELETE RESTRICT,

    CONSTRAINT uq_potpisnik UNIQUE (klient_id, dogovor_id)
);

-- =========================
-- SMETKA
-- =========================
CREATE TABLE smetka (
    smetka_id SERIAL PRIMARY KEY,
    broj_smetka VARCHAR(20) NOT NULL UNIQUE,
    datum_otvaranje DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'AKTIVNA',
    tip_smetka VARCHAR(100) NOT NULL,
    usluga_id INT NOT NULL,
    klient_id INT NOT NULL,
    kredit_id INT,
    banka_id INT NOT NULL,
    valuta_id INT NOT NULL,
    saldo NUMERIC(15,2) DEFAULT 0,

    CONSTRAINT fk_smetka_usluga FOREIGN KEY (usluga_id)
        REFERENCES usluga(usluga_id) ON DELETE RESTRICT,
    CONSTRAINT fk_smetka_klient FOREIGN KEY (klient_id)
        REFERENCES klient(klient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_smetka_kredit FOREIGN KEY (kredit_id)
        REFERENCES kredit(kredit_id) ON DELETE RESTRICT,
    CONSTRAINT fk_smetka_banka FOREIGN KEY (banka_id)
        REFERENCES banka(banka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_smetka_valuta FOREIGN KEY (valuta_id)
        REFERENCES valuta(valuta_id) ON DELETE RESTRICT,

    CONSTRAINT chk_smetka_status CHECK (status IN ('AKTIVNA', 'BLOKIRANA', 'ZATVORENA'))
);

-- =========================
-- DEPOZIT
-- =========================
CREATE TABLE depozit (
    depozit_id SERIAL PRIMARY KEY,
    iznos_depozit NUMERIC(15,2) NOT NULL,
    rok_depozit INT NOT NULL,
    kamatna_stapka NUMERIC(5,2) NOT NULL,
    datum_odobruvanje DATE,
    datum_aktiviranje DATE,
    momentalna_sostojba NUMERIC(15,2),
    tip_depozit VARCHAR(100),
    usluga_id INT NOT NULL,
    smetka_id INT NOT NULL,
    valuta_id INT NOT NULL,

    CONSTRAINT fk_depozit_usluga FOREIGN KEY (usluga_id)
        REFERENCES usluga(usluga_id) ON DELETE RESTRICT,
    CONSTRAINT fk_depozit_smetka FOREIGN KEY (smetka_id)
        REFERENCES smetka(smetka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_depozit_valuta FOREIGN KEY (valuta_id)
        REFERENCES valuta(valuta_id) ON DELETE RESTRICT,

    CONSTRAINT chk_depozit_iznos CHECK (iznos_depozit >= 0),
    CONSTRAINT chk_depozit_sostojba CHECK (momentalna_sostojba IS NULL OR momentalna_sostojba >= 0),
    CONSTRAINT chk_depozit_rok CHECK (rok_depozit > 0),
    CONSTRAINT chk_depozit_kamata CHECK (kamatna_stapka >= 0)
);

-- =========================
-- TIP_KARTICKA / KARTICKA
-- =========================
CREATE TABLE tip_karticka (
    tip_karticka_id SERIAL PRIMARY KEY,
    ime VARCHAR(50) NOT NULL UNIQUE,
    opis VARCHAR(255)
);

CREATE TABLE karticka (
    karticka_id SERIAL PRIMARY KEY,
    broj_karticka VARCHAR(16) NOT NULL UNIQUE,
    datum_izdavanje DATE NOT NULL DEFAULT CURRENT_DATE,
    datum_istekuvanje DATE NOT NULL,
    cvc_kod VARCHAR(3) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'AKTIVNA',
    smetka_id INT NOT NULL,
    tip_karticka_id INT NOT NULL,

    CONSTRAINT fk_karticka_smetka FOREIGN KEY (smetka_id)
        REFERENCES smetka(smetka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_karticka_tip FOREIGN KEY (tip_karticka_id)
        REFERENCES tip_karticka(tip_karticka_id) ON DELETE RESTRICT,

    CONSTRAINT chk_karticka_broj CHECK (length(broj_karticka) = 16),
    CONSTRAINT chk_karticka_cvc CHECK (length(cvc_kod) = 3),
    CONSTRAINT chk_karticka_dates CHECK (datum_istekuvanje > datum_izdavanje),
    CONSTRAINT chk_karticka_status CHECK (status IN ('AKTIVNA', 'BLOKIRANA', 'ISTECENA'))
);

-- =========================
-- NALOG
-- =========================
CREATE TABLE nalog (
    nalog_id SERIAL PRIMARY KEY,
    datum_na_valuta DATE NOT NULL DEFAULT CURRENT_DATE,
    povikuvanje_na_broj_odobruvanje VARCHAR(100),
    iznos NUMERIC(15,2) NOT NULL,
    danocen_broj_embg VARCHAR(13),
    svrha_na_plakjanje VARCHAR(255),
    smetka_primalac_id INT,
    cel_na_doznaka VARCHAR(255),
    hitno BOOLEAN NOT NULL DEFAULT FALSE,
    uplateno_mesto VARCHAR(100),
    smetka_na_budetski_korisnik_edinka_korisnik VARCHAR(100),
    prihodna_sifra VARCHAR(50),
    programa VARCHAR(100),
    nacin_plakjanje VARCHAR(100),
    nalogodavac_id INT NOT NULL,
    danocen_broj_primalac VARCHAR(13),
    smetka_nalogodavac_id INT NOT NULL,
    smetka_nalogoprimac_id INT,
    smetka_nalogoprimac VARCHAR(100),
    valuta_id INT NOT NULL,
    potpisnik_id INT,

    CONSTRAINT fk_nalog_klient FOREIGN KEY (nalogodavac_id)
        REFERENCES klient(klient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_nalog_smetka_nalogodavac FOREIGN KEY (smetka_nalogodavac_id)
        REFERENCES smetka(smetka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_nalog_smetka_primalac FOREIGN KEY (smetka_primalac_id)
        REFERENCES smetka(smetka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_nalog_smetka_nalogoprimac FOREIGN KEY (smetka_nalogoprimac_id)
        REFERENCES smetka(smetka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_nalog_valuta FOREIGN KEY (valuta_id)
        REFERENCES valuta(valuta_id) ON DELETE RESTRICT,
    CONSTRAINT fk_nalog_potpisnik FOREIGN KEY (potpisnik_id)
        REFERENCES potpisnik(potpisnik_id) ON DELETE SET NULL,

    CONSTRAINT chk_nalog_iznos CHECK (iznos >= 0),
    CONSTRAINT chk_nalog_different_accounts CHECK (
        smetka_nalogoprimac_id IS NULL
        OR smetka_nalogodavac_id <> smetka_nalogoprimac_id
    )
);

-- =========================
-- TRANSAKCIJA
-- =========================
CREATE TABLE transakcija (
    transakcija_id SERIAL PRIMARY KEY,
    datum_na_valuta DATE NOT NULL DEFAULT CURRENT_DATE,
    iznos NUMERIC(15,2) NOT NULL,
    datum_transakcija TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    opis VARCHAR(255),
    smetka_isprakjac_id INT NOT NULL,
    smetka_primac_id INT NOT NULL,
    nalog_id INT,
    valuta_id INT NOT NULL,

    CONSTRAINT fk_transakcija_smetka_isprakjac FOREIGN KEY (smetka_isprakjac_id)
        REFERENCES smetka(smetka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transakcija_smetka_primac FOREIGN KEY (smetka_primac_id)
        REFERENCES smetka(smetka_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transakcija_nalog FOREIGN KEY (nalog_id)
        REFERENCES nalog(nalog_id) ON DELETE SET NULL,
    CONSTRAINT fk_transakcija_valuta FOREIGN KEY (valuta_id)
        REFERENCES valuta(valuta_id) ON DELETE RESTRICT,

    CONSTRAINT chk_transakcija_iznos CHECK (iznos >= 0),
    CONSTRAINT chk_transakcija_diff_accounts CHECK (smetka_isprakjac_id <> smetka_primac_id)
);

-- =========================
-- RATA_KREDIT
-- =========================
CREATE TABLE rata_kredit (
    rata_kredit_id SERIAL PRIMARY KEY,
    datum_na_valuta DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'NEPLATENA',
    iznos_rata NUMERIC(15,2) NOT NULL,
    kredit_id INT NOT NULL,
    transakcija_id INT,

    CONSTRAINT fk_rata_kredit_kredit FOREIGN KEY (kredit_id)
        REFERENCES kredit(kredit_id) ON DELETE RESTRICT,
    CONSTRAINT fk_rata_kredit_transakcija FOREIGN KEY (transakcija_id)
        REFERENCES transakcija(transakcija_id) ON DELETE SET NULL,

    CONSTRAINT chk_rata_kredit_iznos CHECK (iznos_rata >= 0),
    CONSTRAINT chk_rata_kredit_status CHECK (status IN ('PLATENA', 'NEPLATENA', 'DOCNI'))
);

/* ============================================================
   VIEWS - BANK PROJECT
   ============================================================ */

-- 1. ДЕТАЛЕН ПРЕГЛЕД НА СМЕТКИ
-- Со име на клиент, салдо и валута
CREATE OR REPLACE VIEW vw_smetki_detali AS
SELECT
    s.smetka_id,
    s.broj_smetka,
    s.tip_smetka,
    s.saldo,
    v.kod AS valuta,
    k.klient_id,
    k.ime,
    k.prezime,
    k.embg,
    s.status
FROM smetka s
JOIN klient k ON s.klient_id = k.klient_id
JOIN valuta v ON s.valuta_id = v.valuta_id;


-- 2. МОНИТОРИНГ НА КАРТИЧКИ
-- Картички поврзани со сопственикот преку сметка
CREATE OR REPLACE VIEW vw_karticki_klienti AS
SELECT
    ka.karticka_id,
    ka.broj_karticka,
    ka.status AS karticka_status,
    ka.datum_istekuvanje,
    tk.ime AS tip_karticka,
    s.smetka_id,
    s.broj_smetka,
    s.klient_id,
    k.ime,
    k.prezime
FROM karticka ka
JOIN tip_karticka tk ON ka.tip_karticka_id = tk.tip_karticka_id
JOIN smetka s ON ka.smetka_id = s.smetka_id
JOIN klient k ON s.klient_id = k.klient_id;


-- 3. КРЕДИТИ И СТАТУС НА РАТИ
-- Проверка на секоја рата поединечно, поврзана со клиент преку сметка
CREATE OR REPLACE VIEW vw_kreditni_rati_status AS
SELECT
    kr.kredit_id,
    s.klient_id,
    k.ime,
    k.prezime,
    r.rata_kredit_id,
    r.iznos_rata,
    r.datum_na_valuta,
    r.status AS status_rata,
    v.kod AS valuta
FROM rata_kredit r
JOIN kredit kr ON r.kredit_id = kr.kredit_id
JOIN smetka s ON s.kredit_id = kr.kredit_id
JOIN klient k ON s.klient_id = k.klient_id
JOIN valuta v ON kr.valuta_id = v.valuta_id;


-- 4. ТРАНСАКЦИОНЕН ЛОГ
-- Со имиња и id на испраќач и примач
CREATE OR REPLACE VIEW vw_transakcii_iminja AS
SELECT
    t.transakcija_id,
    t.datum_transakcija,
    t.iznos,

    t.smetka_isprakjac_id,
    s_od.broj_smetka AS isprakjac_broj_smetka,
    s_od.klient_id AS isprakjac_klient_id,
    k_od.ime AS isprakjac_ime,
    k_od.prezime AS isprakjac_prezime,

    t.smetka_primac_id,
    s_do.broj_smetka AS primac_broj_smetka,
    s_do.klient_id AS primac_klient_id,
    k_do.ime AS primac_ime,
    k_do.prezime AS primac_prezime,

    t.opis
FROM transakcija t
JOIN smetka s_od ON t.smetka_isprakjac_id = s_od.smetka_id
JOIN klient k_od ON s_od.klient_id = k_od.klient_id
JOIN smetka s_do ON t.smetka_primac_id = s_do.smetka_id
JOIN klient k_do ON s_do.klient_id = k_do.klient_id;


-- 5. ЦЕНТРАЛЕН КЛИЕНТСКИ АДРЕСАР
CREATE OR REPLACE VIEW vw_klient_kontakt_info AS
SELECT
    k.klient_id,
    k.ime,
    k.prezime,
    bu.username,
    t.telefonski_broj,
    e.email,
    concat(a.grad, ', ', a.ulica, ' ', a.broj) AS adresa
FROM klient k
JOIN bank_user bu ON k.user_id = bu.user_id
LEFT JOIN telefon t ON k.klient_id = t.klient_id
LEFT JOIN email e ON k.klient_id = e.klient_id
LEFT JOIN adresa a ON k.klient_id = a.klient_id;


-- 6. ПРЕГЛЕД НА ДЕПОЗИТИ ПО КЛИЕНТ
CREATE OR REPLACE VIEW vw_depoziti_klienti AS
SELECT
    d.depozit_id,
    d.smetka_id,
    s.klient_id,
    d.iznos_depozit,
    d.kamatna_stapka,
    d.tip_depozit,
    k.ime,
    k.prezime,
    s.broj_smetka
FROM depozit d
JOIN smetka s ON d.smetka_id = s.smetka_id
JOIN klient k ON s.klient_id = k.klient_id;


-- 7. ПРАВНИ ДОГОВОРИ
-- Со клиент и услуга
CREATE OR REPLACE VIEW vw_dogovori_detali AS
SELECT
    d.dogovor_id,
    d.klient_id,
    d.usluga_id,
    d.naslov,
    d.status,
    d.datum_potpisuvanje,
    k.ime,
    k.prezime,
    u.ime AS usluga_ime
FROM dogovor d
JOIN klient k ON d.klient_id = k.klient_id
JOIN usluga u ON d.usluga_id = u.usluga_id;


-- 8. АНАЛИТИКА НА ПРОИЗВОДИ ПО КЛИЕНТ
-- Подобра верзија без correlated subqueries
CREATE OR REPLACE VIEW vw_klient_engagement AS
SELECT
    k.klient_id,
    k.ime,
    k.prezime,
    COUNT(DISTINCT s.smetka_id) AS broj_smetki,
    COUNT(DISTINCT d.dogovor_id) AS broj_dogovori
FROM klient k
LEFT JOIN smetka s ON k.klient_id = s.klient_id
LEFT JOIN dogovor d ON k.klient_id = d.klient_id
GROUP BY k.klient_id, k.ime, k.prezime;


-- 9. ПРЕГЛЕД НА НАЛОЗИ
-- Плаќања по клиент и сметка
CREATE OR REPLACE VIEW vw_nalozi_klienti AS
SELECT
    n.nalog_id,
    n.iznos,
    n.svrha_na_plakjanje,
    n.datum_na_valuta,
    n.nalogodavac_id AS klient_id,
    n.smetka_nalogodavac_id,
    k.ime,
    k.prezime,
    s.broj_smetka AS od_smetka
FROM nalog n
JOIN klient k ON n.nalogodavac_id = k.klient_id
JOIN smetka s ON n.smetka_nalogodavac_id = s.smetka_id;



/* ============================================================
   SELECT QUERIES FOR ANALYSIS
   First run these WITHOUT indexes.
   Then create indexes and run the same queries again.
   ============================================================ */

-- View 1
SELECT *
FROM vw_smetki_detali
WHERE klient_id = 50000;

-- View 2
SELECT *
FROM vw_karticki_klienti
WHERE klient_id = 50000;

-- View 3
SELECT *
FROM vw_kreditni_rati_status
WHERE klient_id = 50000;

-- Alternative for View 3 by credit
SELECT *
FROM vw_kreditni_rati_status
WHERE kredit_id = 1000;

-- View 4 - outgoing transactions
SELECT *
FROM vw_transakcii_iminja
WHERE isprakjac_klient_id = 50000;

-- View 4 - incoming transactions
SELECT *
FROM vw_transakcii_iminja
WHERE primac_klient_id = 50000;

-- Alternative for View 4 by sender account
SELECT *
FROM vw_transakcii_iminja
WHERE smetka_isprakjac_id = 10000;

-- Alternative for View 4 by receiver account
SELECT *
FROM vw_transakcii_iminja
WHERE smetka_primac_id = 10001;

-- View 5
SELECT *
FROM vw_klient_kontakt_info
WHERE klient_id = 50000;

-- View 6
SELECT *
FROM vw_depoziti_klienti
WHERE klient_id = 50000;

-- View 7
SELECT *
FROM vw_dogovori_detali
WHERE klient_id = 50000;

-- View 8
SELECT *
FROM vw_klient_engagement
WHERE klient_id = 50000;

-- View 9
SELECT *
FROM vw_nalozi_klienti
WHERE klient_id = 50000;



/* ============================================================
   EXPLAIN ANALYZE VERSION
   Use these for screenshots and execution time.
   ============================================================ */

-- View 1
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_smetki_detali
WHERE klient_id = 50000;

-- View 2
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_karticki_klienti
WHERE klient_id = 50000;

-- View 3
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_kreditni_rati_status
WHERE klient_id = 50000;

-- View 3 alternative
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_kreditni_rati_status
WHERE kredit_id = 1000;

-- View 4 outgoing
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_transakcii_iminja
WHERE isprakjac_klient_id = 50000;

-- View 4 incoming
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_transakcii_iminja
WHERE primac_klient_id = 50000;

-- View 4 by sender account
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_transakcii_iminja
WHERE smetka_isprakjac_id = 10000;

-- View 4 by receiver account
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_transakcii_iminja
WHERE smetka_primac_id = 10001;

-- View 5
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_klient_kontakt_info
WHERE klient_id = 50000;

-- View 6
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_depoziti_klienti
WHERE klient_id = 50000;

-- View 7
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_dogovori_detali
WHERE klient_id = 50000;

-- View 8
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_klient_engagement
WHERE klient_id = 50000;

-- View 9
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_nalozi_klienti
WHERE klient_id = 50000;



/* ============================================================
   DROP INDEXES
   Use this if you want to test from beginning without indexes.
   ============================================================ */

DROP INDEX IF EXISTS idx_smetka_klient_id;
DROP INDEX IF EXISTS idx_smetka_valuta_id;
DROP INDEX IF EXISTS idx_karticka_smetka_id;
DROP INDEX IF EXISTS idx_karticka_tip_karticka_id;
DROP INDEX IF EXISTS idx_rata_kredit_kredit_id;
DROP INDEX IF EXISTS idx_smetka_kredit_id;
DROP INDEX IF EXISTS idx_transakcija_isprakjac;
DROP INDEX IF EXISTS idx_transakcija_primac;
DROP INDEX IF EXISTS idx_telefon_klient_id;
DROP INDEX IF EXISTS idx_email_klient_id;
DROP INDEX IF EXISTS idx_adresa_klient_id;
DROP INDEX IF EXISTS idx_depozit_smetka_id;
DROP INDEX IF EXISTS idx_dogovor_klient_id;
DROP INDEX IF EXISTS idx_dogovor_usluga_id;
DROP INDEX IF EXISTS idx_nalog_nalogodavac_id;
DROP INDEX IF EXISTS idx_nalog_smetka_nalogodavac_id;



/* ============================================================
   CREATE INDEXES
   Create these after taking screenshots without indexes.
   ============================================================ */

-- For View 1 and many other views
CREATE INDEX idx_smetka_klient_id
ON smetka(klient_id);

CREATE INDEX idx_smetka_valuta_id
ON smetka(valuta_id);

-- For View 2
CREATE INDEX idx_karticka_smetka_id
ON karticka(smetka_id);

CREATE INDEX idx_karticka_tip_karticka_id
ON karticka(tip_karticka_id);

-- For View 3
CREATE INDEX idx_rata_kredit_kredit_id
ON rata_kredit(kredit_id);

CREATE INDEX idx_smetka_kredit_id
ON smetka(kredit_id);

-- For View 4
CREATE INDEX idx_transakcija_isprakjac
ON transakcija(smetka_isprakjac_id);

CREATE INDEX idx_transakcija_primac
ON transakcija(smetka_primac_id);

-- For View 5
CREATE INDEX idx_telefon_klient_id
ON telefon(klient_id);

CREATE INDEX idx_email_klient_id
ON email(klient_id);

CREATE INDEX idx_adresa_klient_id
ON adresa(klient_id);

-- For View 6
CREATE INDEX idx_depozit_smetka_id
ON depozit(smetka_id);

-- For View 7 and View 8
CREATE INDEX idx_dogovor_klient_id
ON dogovor(klient_id);

CREATE INDEX idx_dogovor_usluga_id
ON dogovor(usluga_id);

-- For View 9
CREATE INDEX idx_nalog_nalogodavac_id
ON nalog(nalogodavac_id);

CREATE INDEX idx_nalog_smetka_nalogodavac_id
ON nalog(smetka_nalogodavac_id);



/* ============================================================
   INSERT / UPDATE TESTS FOR EVERY VIEW
   SAFE VERSION WITH BEGIN + ROLLBACK
   IMPORTANT: EXPLAIN ANALYZE REALLY EXECUTES INSERT/UPDATE.
   ROLLBACK makes sure test data is not saved permanently.
   ============================================================ */


/* ============================================================
   VIEW 1: vw_smetki_detali
   Main table: smetka
   ============================================================ */

-- UPDATE test for View 1
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE smetka
SET saldo = saldo + 100
WHERE klient_id = 50000;

ROLLBACK;


-- INSERT test for View 1
-- Fixed: added banka_id and usluga_id
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO smetka
(broj_smetka, tip_smetka, saldo, valuta_id, klient_id, status, usluga_id, banka_id)
SELECT
    '999999000001',
    'TEKOVNA',
    1000.00,
    (SELECT valuta_id FROM valuta LIMIT 1),
    (SELECT klient_id FROM klient WHERE klient_id = 50000 LIMIT 1),
    'AKTIVNA',
    (SELECT usluga_id FROM usluga LIMIT 1),
    (SELECT banka_id FROM banka LIMIT 1);

ROLLBACK;



/* ============================================================
   VIEW 2: vw_karticki_klienti
   Main table: karticka
   ============================================================ */

-- UPDATE test for View 2
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE karticka
SET status = 'AKTIVNA'
WHERE smetka_id = 10000;

ROLLBACK;


-- INSERT test for View 2
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO karticka
(broj_karticka, status, datum_istekuvanje, cvc_kod, tip_karticka_id, smetka_id)
SELECT
    '9999888877766666',
    'AKTIVNA',
    CURRENT_DATE + INTERVAL '3 years',
    123,
    (SELECT tip_karticka_id FROM tip_karticka LIMIT 1),
    (SELECT smetka_id FROM smetka WHERE smetka_id = 10500 LIMIT 1);

ROLLBACK;



/* ============================================================
   VIEW 3: vw_kreditni_rati_status
   Main table: rata_kredit
   ============================================================ */

-- UPDATE test for View 3
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE rata_kredit
SET status = 'PLATENA'
WHERE kredit_id = 1000;

ROLLBACK;


-- INSERT test for View 3
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO rata_kredit
(kredit_id, iznos_rata, datum_na_valuta, status)
SELECT
    (SELECT kredit_id FROM kredit WHERE kredit_id = 1000 LIMIT 1),
    5000.00,
    CURRENT_DATE + INTERVAL '1 month',
    'NEPLATENA';

ROLLBACK;



/* ============================================================
   VIEW 4: vw_transakcii_iminja
   Main table: transakcija
   ============================================================ */

-- UPDATE test for View 4
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE transakcija
SET opis = 'test update transakcija'
WHERE smetka_isprakjac_id = 10000;

ROLLBACK;


-- INSERT test for View 4
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO transakcija
(datum_transakcija, iznos, smetka_isprakjac_id, smetka_primac_id, opis, valuta_id)
SELECT
    CURRENT_DATE,
    1000.00,
    (SELECT smetka_id FROM smetka WHERE smetka_id = 10001 LIMIT 1),
    (SELECT smetka_id FROM smetka WHERE smetka_id = 10002 LIMIT 1),
    'test transakcija',
    (SELECT valuta_id FROM valuta LIMIT 1);

ROLLBACK;



/* ============================================================
   VIEW 5: vw_klient_kontakt_info
   Main tables: email, telefon, adresa
   ============================================================ */

-- UPDATE test for View 5 - email
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE email
SET email = 'test50000@gmail.com'
WHERE klient_id = 50000;

ROLLBACK;


-- INSERT test for View 5 - email
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO email
(klient_id, email)
SELECT
    (SELECT klient_id FROM klient WHERE klient_id = 50000 LIMIT 1),
    'nov.email50000@gmail.com';

ROLLBACK;


-- UPDATE test for View 5 - telefon
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE telefon
SET telefonski_broj = '070000000'
WHERE klient_id = 50000;

ROLLBACK;


-- INSERT test for View 5 - telefon
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO telefon
(klient_id, telefonski_broj)
SELECT
    (SELECT klient_id FROM klient WHERE klient_id = 50000 LIMIT 1),
    '071111111';

ROLLBACK;


-- UPDATE test for View 5 - adresa
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE adresa
SET ulica = 'Test Ulica'
WHERE klient_id = 50000;

ROLLBACK;


-- INSERT test for View 5 - adresa
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO adresa
(klient_id, grad, ulica, broj)
SELECT
    (SELECT klient_id FROM klient WHERE klient_id = 50000 LIMIT 1),
    'Skopje',
    'Test Ulica',
    '1';

ROLLBACK;



/* ============================================================
   VIEW 6: vw_depoziti_klienti
   Main table: depozit
   ============================================================ */

-- UPDATE test for View 6
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE depozit
SET kamatna_stapka = kamatna_stapka + 0.1
WHERE smetka_id = 10000;

ROLLBACK;


-- INSERT test for View 6
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO depozit
(
    iznos_depozit,
    rok_depozit,
    kamatna_stapka,
    tip_depozit,
    usluga_id,
    smetka_id,
    valuta_id
)
SELECT
    20000.00,
    12,
    3.5,
    'OROCEN',
    (SELECT usluga_id FROM usluga LIMIT 1),
    (SELECT smetka_id FROM smetka WHERE smetka_id = 10000 LIMIT 1),
    (SELECT valuta_id FROM valuta LIMIT 1);

ROLLBACK;



/* ============================================================
   VIEW 7: vw_dogovori_detali
   Main table: dogovor
   ============================================================ */

-- UPDATE test for View 7
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE dogovor
SET status = 'KREIRAN'
WHERE klient_id = 50000;

ROLLBACK;


-- INSERT test for View 7
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO dogovor
(
    klient_id,
    banka_id,
    usluga_id,
    naslov,
    status,
    datum_potpisuvanje
)
SELECT
    (SELECT klient_id FROM klient WHERE klient_id = 50000 LIMIT 1),
    (SELECT banka_id FROM banka LIMIT 1),
    (SELECT usluga_id FROM usluga LIMIT 1),
    'Test dogovor',
    'KREIRAN',
    CURRENT_DATE;

ROLLBACK;



/* ============================================================
   VIEW 8: vw_klient_engagement
   Main tables: smetka, dogovor
   ============================================================ */

-- UPDATE test for View 8 - smetka
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE smetka
SET saldo = saldo + 50
WHERE klient_id = 50000;

ROLLBACK;


-- INSERT test for View 8 - smetka
-- Fixed: added banka_id and usluga_id
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO smetka
(broj_smetka, tip_smetka, saldo, valuta_id, klient_id, status, usluga_id, banka_id)
SELECT
    '999999000002',
    'TEKOVNA',
    500.00,
    (SELECT valuta_id FROM valuta LIMIT 1),
    (SELECT klient_id FROM klient WHERE klient_id = 50000 LIMIT 1),
    'AKTIVNA',
    (SELECT usluga_id FROM usluga LIMIT 1),
    (SELECT banka_id FROM banka LIMIT 1);

ROLLBACK;


-- UPDATE test for View 8 - dogovor
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE dogovor
SET status = 'AKTIVEN'
WHERE klient_id = 50000;

ROLLBACK;


-- INSERT test for View 8 - dogovor
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO dogovor
(klient_id, usluga_id, naslov, status, datum_potpisuvanje)
SELECT
    (SELECT klient_id FROM klient WHERE klient_id = 50000 LIMIT 1),
    (SELECT usluga_id FROM usluga LIMIT 1),
    'Test dogovor engagement',
    'AKTIVEN',
    CURRENT_DATE;

ROLLBACK;



/* ============================================================
   VIEW 9: vw_nalozi_klienti
   Main table: nalog
   ============================================================ */

-- UPDATE test for View 9
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE nalog
SET svrha_na_plakjanje = 'test update nalog_v1'
WHERE nalogodavac_id = 50000;

ROLLBACK;


-- INSERT test for View 9
BEGIN;

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO nalog
(
    iznos,
    svrha_na_plakjanje,
    datum_na_valuta,
    nalogodavac_id,
    smetka_nalogodavac_id,
    valuta_id
)
SELECT
    1500.00,
    'test uplata',
    CURRENT_DATE,
    (SELECT klient_id FROM klient WHERE klient_id = 50000 LIMIT 1),
    (SELECT smetka_id FROM smetka WHERE smetka_id = 10000 LIMIT 1),
    (SELECT valuta_id FROM valuta LIMIT 1);

ROLLBACK;


SELECT table_name,
       (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I', table_name), false, true, '')))[1]::text::int AS row_count
FROM information_schema.tables
WHERE table_schema = 'public';


-- ==========================================================
-- DML DATA GENERATION SCRIPT FOR BANK DATABASE
-- Converted from Python CSV generator to PostgreSQL DML
-- Author: generated for Krume
-- Purpose: fill existing tables directly with INSERT INTO ... SELECT
-- ==========================================================

BEGIN;

-- If you already inserted partial data and got an error, run TRUNCATE first.
-- This script is intended for an empty database or freshly truncated tables.

-- ==========================================================
-- Recommended load order:
-- banka, valuta, kursna_lista, bank_user, role, privilegii,
-- role_privilegii, role_user, filijala, klient, vraboten,
-- raboti_vo, izvestuvanje, telefon, email, adresa, usluga,
-- tip_kredit, kredit, dogovor, potpisnik, smetka, depozit,
-- tip_karticka, karticka, nalog, transakcija, rata_kredit
-- ==========================================================

-- ==========================================================
-- 1. STATIC BANK DATA
-- ==========================================================

INSERT INTO banka (banka_id, ime_na_banka, edb, datum_na_osnovanje)
SELECT gs,
       (ARRAY[
           'Komercijalna Banka', 'Stopanska Banka', 'NLB Banka', 'Halkbank',
           'Silk Road Bank', 'Sparkasse Bank', 'TTK Banka', 'Unibanka',
           'Centralna Kooperativna Banka', 'ProCredit Bank'
       ])[((gs - 1) % 10) + 1],
       RIGHT('5' || LPAD(gs::text, 12, '0'), 13),
       CURRENT_DATE - ((2000 + floor(random() * 13000))::int)
FROM generate_series(1, 10) gs;

INSERT INTO valuta (valuta_id, kod, ime, simbol)
VALUES
    (1, 'MKD', 'Makedonski denar', 'ден'),
    (2, 'EUR', 'Euro', '€'),
    (3, 'USD', 'US Dollar', '$'),
    (4, 'CHF', 'Swiss Franc', 'CHF'),
    (5, 'GBP', 'British Pound', '£');

INSERT INTO kursna_lista (kurs_id, datum, kupoven_kurs, sreden_kurs, prodazen_kurs, valuta_od_id, valuta_do_id)
WITH dates AS (
    SELECT generate_series(CURRENT_DATE - INTERVAL '29 days', CURRENT_DATE, INTERVAL '1 day')::date AS datum
), rates AS (
    SELECT * FROM (VALUES
        (2, 61.50::numeric),
        (3, 56.70::numeric),
        (4, 64.20::numeric),
        (5, 72.10::numeric)
    ) AS r(valuta_id, base_rate)
), generated AS (
    SELECT row_number() OVER (ORDER BY d.datum, r.valuta_id) AS kurs_id,
           d.datum,
           r.valuta_id,
           r.base_rate + ((random() - 0.5) * 2)::numeric AS mid
    FROM dates d
    CROSS JOIN rates r
)
SELECT kurs_id,
       datum,
       round(mid - 0.25, 4),
       round(mid, 4),
       round(mid + 0.25, 4),
       valuta_id,
       1
FROM generated;

-- ==========================================================
-- 2. USERS, ROLES AND PRIVILEGES
-- ==========================================================

INSERT INTO bank_user (user_id, username, password_hash, status)
SELECT gs,
       'user_' || gs,
       md5('password_' || gs),
       CASE WHEN gs % 20 = 0 THEN 'NEAKTIVEN' ELSE 'AKTIVEN' END
FROM generate_series(1, 110000) gs;

INSERT INTO role (role_id, ime)
VALUES
    (1, 'CLIENT'),
    (2, 'EMPLOYEE'),
    (3, 'ADMIN');

INSERT INTO privilegii (privilegija_id, privilegija)
VALUES
    (1, 'VIEW_ACCOUNT'),
    (2, 'CREATE_PAYMENT'),
    (3, 'VIEW_TRANSACTIONS'),
    (4, 'MANAGE_CLIENTS'),
    (5, 'APPROVE_LOAN'),
    (6, 'ADMIN_PANEL');

INSERT INTO role_privilegii (role_id, privilegija_id)
VALUES
    (1, 1), (1, 2), (1, 3),
    (2, 1), (2, 3), (2, 4), (2, 5),
    (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6);

INSERT INTO role_user (role_id, user_id)
SELECT CASE
           WHEN gs <= 100000 THEN 1
           WHEN gs <= 110000 THEN 2
           ELSE 3
       END AS role_id,
       gs AS user_id
FROM generate_series(1, 110000) gs;

-- ==========================================================
-- 3. BRANCHES
-- ==========================================================

INSERT INTO filijala (filijala_id, ime, banka_id)
SELECT gs,
       'Filijala_' || gs || '_' ||
       (ARRAY['Skopje','Bitola','Ohrid','Prilep','Tetovo','Kumanovo','Veles','Stip','Strumica','Gostivar'])[(gs % 10) + 1],
       ((gs - 1) % 10) + 1
FROM generate_series(1, 100) gs;

-- ==========================================================
-- 4. CLIENTS AND EMPLOYEES
-- ==========================================================

-- FIX: replace the old INSERT INTO klient block with this one.
-- Reason: embg is UNIQUE, so the 3-digit final index must be unique inside each
-- birth_date + city_code + gender group.

INSERT INTO klient (klient_id, user_id, ime, prezime, datum_ragjanje, tatkovo_ime, embg)
WITH person_raw AS (
    SELECT gs,
           CASE WHEN gs % 2 = 0 THEN 'M' ELSE 'F' END AS gender,
           CASE WHEN gs % 2 = 0 THEN
               (ARRAY['Aleksandar','Bojan','Stefan','Marko','Petar','Martin','David','Filip','Nikola','Krumislav','Vladimir','Andrej','Darko','Igor','Goran','Dejan','Mile','Tome','Antonio','Kristijan','Mihail','Damjan','Dimitar','Luka','Matej','Viktor','Daniel','Jovan'])[((gs * 7) % 28) + 1]
           ELSE
               (ARRAY['Sara','Ana','Marija','Elena','Ivana','Jovana','Kristina','Simona','Teodora','Angela','Mila','Tamara','Monika','Viktorija','Bojana','Katerina','Martina','Stefanija','Maja','Biljana','Aleksandra','Anastasija','Mia','Lara','Eva','Irena','Natalija'])[((gs * 7) % 27) + 1]
           END AS ime,
           CASE WHEN gs % 2 = 0 THEN
               (ARRAY['Petrovski','Trajkovski','Stojanovski','Ristovski','Jovanovski','Nikolovski','Tasevski','Bojinovski','Mitrevski','Georgievski','Atanasovski','Kostovski','Dimitrovski','Popovski','Ilievski','Mladenovski','Kolevski','Naumovski','Kuzmanovski','Krstevski'])[((gs * 11) % 20) + 1]
           ELSE
               (ARRAY['Petrovska','Trajkovska','Stojanovska','Ristovska','Jovanovska','Nikolovska','Tasevska','Bojinovska','Mitrevska','Georgievska','Atanasovska','Kostovska','Dimitrovska','Popovska','Ilievska','Mladenovska','Kolevska','Naumovska','Kuzmanovska','Krstevska'])[((gs * 11) % 20) + 1]
           END AS prezime,
           (ARRAY['Aleksandar','Bojan','Stefan','Marko','Petar','Martin','David','Filip','Nikola','Vladimir','Andrej','Darko','Igor','Goran','Dejan'])[((gs * 13) % 15) + 1] AS tatkovo_ime,

           -- deterministic birthdate instead of random, so distribution is stable
           make_date(
               (1946 + ((gs * 37) % 62))::int,
               (1 + ((gs * 17) % 12))::int,
               (1 + ((gs * 19) % 28))::int
           ) AS birth_date,

           (ARRAY['45','46','47','48','49','50','51','52','53','54'])[((gs * 23) % 10) + 1] AS city_code
    FROM generate_series(1, 100000) gs
), person AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY birth_date, city_code, gender
               ORDER BY gs
           ) AS embg_seq
    FROM person_raw
)
SELECT gs,
       gs,
       ime,
       prezime,
       birth_date,
       tatkovo_ime,
       LPAD(EXTRACT(DAY FROM birth_date)::int::text, 2, '0') ||
       LPAD(EXTRACT(MONTH FROM birth_date)::int::text, 2, '0') ||
       LPAD((EXTRACT(YEAR FROM birth_date)::int % 1000)::text, 3, '0') ||
       city_code ||
       CASE WHEN gender = 'M' THEN '0' ELSE '5' END ||
       LPAD(embg_seq::text, 3, '0') AS embg
FROM person;

-- Optional same fix for vraboten, because vraboten.embg is also UNIQUE.

INSERT INTO vraboten (vraboten_id, user_id, ime, prezime, tatkovo_ime, datum_ragjanje, embg)
WITH person_raw AS (
    SELECT gs,
           100000 + gs AS user_id,
           CASE WHEN gs % 2 = 0 THEN 'M' ELSE 'F' END AS gender,
           CASE WHEN gs % 2 = 0 THEN
               (ARRAY['Aleksandar','Bojan','Stefan','Marko','Petar','Martin','David','Filip','Nikola','Krumislav','Vladimir','Andrej','Darko','Igor','Goran','Dejan','Mile','Tome','Antonio','Kristijan','Mihail','Damjan','Dimitar','Luka','Matej','Viktor','Daniel','Jovan'])[((gs * 7) % 28) + 1]
           ELSE
               (ARRAY['Sara','Ana','Marija','Elena','Ivana','Jovana','Kristina','Simona','Teodora','Angela','Mila','Tamara','Monika','Viktorija','Bojana','Katerina','Martina','Stefanija','Maja','Biljana','Aleksandra','Anastasija','Mia','Lara','Eva','Irena','Natalija'])[((gs * 7) % 27) + 1]
           END AS ime,
           CASE WHEN gs % 2 = 0 THEN
               (ARRAY['Petrovski','Trajkovski','Stojanovski','Ristovski','Jovanovski','Nikolovski','Tasevski','Bojinovski','Mitrevski','Georgievski','Atanasovski','Kostovski','Dimitrovski','Popovski','Ilievski','Mladenovski','Kolevski','Naumovski','Kuzmanovski','Krstevski'])[((gs * 11) % 20) + 1]
           ELSE
               (ARRAY['Petrovska','Trajkovska','Stojanovska','Ristovska','Jovanovska','Nikolovska','Tasevska','Bojinovska','Mitrevska','Georgievska','Atanasovska','Kostovska','Dimitrovska','Popovska','Ilievska','Mladenovska','Kolevska','Naumovska','Kuzmanovska','Krstevska'])[((gs * 11) % 20) + 1]
           END AS prezime,
           (ARRAY['Aleksandar','Bojan','Stefan','Marko','Petar','Martin','David','Filip','Nikola','Vladimir','Andrej','Darko','Igor','Goran','Dejan'])[((gs * 13) % 15) + 1] AS tatkovo_ime,
           make_date(
               (1961 + ((gs * 37) % 44))::int,
               (1 + ((gs * 17) % 12))::int,
               (1 + ((gs * 19) % 28))::int
           ) AS birth_date,
           (ARRAY['45','46','47','48','49','50','51','52','53','54'])[((gs * 23) % 10) + 1] AS city_code
    FROM generate_series(1, 10000) gs
), person AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY birth_date, city_code, gender
               ORDER BY gs
           ) AS embg_seq
    FROM person_raw
)
SELECT gs,
       user_id,
       ime,
       prezime,
       tatkovo_ime,
       birth_date,
       LPAD(EXTRACT(DAY FROM birth_date)::int::text, 2, '0') ||
       LPAD(EXTRACT(MONTH FROM birth_date)::int::text, 2, '0') ||
       LPAD((EXTRACT(YEAR FROM birth_date)::int % 1000)::text, 3, '0') ||
       city_code ||
       CASE WHEN gender = 'M' THEN '0' ELSE '5' END ||
       LPAD(embg_seq::text, 3, '0') AS embg
FROM person;

INSERT INTO raboti_vo (vraboten_id, filijala_id, raboti_od, raboti_do)
SELECT gs,
       ((gs - 1) % 100) + 1,
       CURRENT_DATE - ((30 + floor(random() * 2970))::int),
       NULL
FROM generate_series(1, 10000) gs;

-- ==========================================================
-- 5. CONTACT DATA
-- FIXED V3: no UNION ALL is used in contact data.
-- This avoids PostgreSQL UNION type resolution errors completely.
-- ==========================================================

-- TELEFON: clients
INSERT INTO telefon (telefon_id, telefonski_broj, tip_telefon, klient_id, vraboten_id, banka_id, filijala_id)
SELECT gs::int,
       ('+3897' || ((gs % 8) + 1)::text || LPAD(gs::text, 6, '0'))::varchar(20),
       'MOBILEN'::varchar(50),
       gs::int,
       NULL::int,
       NULL::int,
       NULL::int
FROM generate_series(1, 100000) AS gs;

-- TELEFON: employees
INSERT INTO telefon (telefon_id, telefonski_broj, tip_telefon, klient_id, vraboten_id, banka_id, filijala_id)
SELECT (100000 + gs)::int,
       ('+3892' || (200000 + gs)::text)::varchar(20),
       'SLUZBEN'::varchar(50),
       NULL::int,
       gs::int,
       NULL::int,
       NULL::int
FROM generate_series(1, 10000) AS gs;

-- TELEFON: banks
INSERT INTO telefon (telefon_id, telefonski_broj, tip_telefon, klient_id, vraboten_id, banka_id, filijala_id)
SELECT (110000 + gs)::int,
       ('+3892' || (300000 + gs)::text)::varchar(20),
       'CENTRALA'::varchar(50),
       NULL::int,
       NULL::int,
       gs::int,
       NULL::int
FROM generate_series(1, 10) AS gs;

-- TELEFON: branches
INSERT INTO telefon (telefon_id, telefonski_broj, tip_telefon, klient_id, vraboten_id, banka_id, filijala_id)
SELECT (110010 + gs)::int,
       ('+3892' || (400000 + gs)::text)::varchar(20),
       'FILIJALA'::varchar(50),
       NULL::int,
       NULL::int,
       NULL::int,
       gs::int
FROM generate_series(1, 100) AS gs;

-- EMAIL: clients
INSERT INTO email (email_id, email, tip_email, klient_id, vraboten_id, banka_id, filijala_id)
SELECT k.klient_id::int,
       lower(k.ime || '.' || k.prezime || k.klient_id || CASE WHEN k.klient_id % 2 = 0 THEN '@gmail.com' ELSE '@yahoo.com' END)::varchar(100),
       'LICEN'::varchar(50),
       k.klient_id::int,
       NULL::int,
       NULL::int,
       NULL::int
FROM klient k;

-- EMAIL: employees
INSERT INTO email (email_id, email, tip_email, klient_id, vraboten_id, banka_id, filijala_id)
SELECT (100000 + v.vraboten_id)::int,
       lower(v.ime || '.' || v.prezime || v.vraboten_id || '@bank.mk')::varchar(100),
       'SLUZBEN'::varchar(50),
       NULL::int,
       v.vraboten_id::int,
       NULL::int,
       NULL::int
FROM vraboten v;

-- EMAIL: banks
INSERT INTO email (email_id, email, tip_email, klient_id, vraboten_id, banka_id, filijala_id)
SELECT (110000 + gs)::int,
       ('contact' || gs || '@bank.mk')::varchar(100),
       'KONTAKT'::varchar(50),
       NULL::int,
       NULL::int,
       gs::int,
       NULL::int
FROM generate_series(1, 10) AS gs;

-- EMAIL: branches
INSERT INTO email (email_id, email, tip_email, klient_id, vraboten_id, banka_id, filijala_id)
SELECT (110010 + gs)::int,
       ('branch' || gs || '@bank.mk')::varchar(100),
       'FILIJALA'::varchar(50),
       NULL::int,
       NULL::int,
       NULL::int,
       gs::int
FROM generate_series(1, 100) AS gs;

-- ADRESA: clients
INSERT INTO adresa (adresa_id, drzava, grad, opstina, naselba, ulica, broj, stanben_broj, tip_adresa, klient_id, vraboten_id, banka_id, filijala_id)
SELECT gs::int,
       'Makedonija'::varchar(100),
       (ARRAY['Skopje','Bitola','Ohrid','Prilep','Tetovo','Kumanovo','Veles','Stip','Strumica','Gostivar'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Centar','Karposh','Aerodrom','Gazi Baba','Kisela Voda','Chair','Bitola','Ohrid','Prilep','Tetovo'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Debar Maalo','Kapistec','Karposh 1','Novo Lisiche','Avtokomanda','Bair','Varosh','Dva Bresta','Senjak','Bansko'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Partizanska','Ilindenska','Makedonija','Vodnjanska','Dame Gruev','Jane Sandanski','ASNOM','Goce Delcev','11 Oktomvri','Orce Nikolov','Boris Trajkovski','Krste Misirkov','Kuzman Josifovski Pitu'])[(gs % 13) + 1]::varchar(150),
       ((gs % 200) + 1)::text::varchar(20),
       ((gs % 40) + 1)::text::varchar(20),
       'KLIENT'::varchar(50),
       gs::int,
       NULL::int,
       NULL::int,
       NULL::int
FROM generate_series(1, 100000) AS gs;

-- ADRESA: employees
INSERT INTO adresa (adresa_id, drzava, grad, opstina, naselba, ulica, broj, stanben_broj, tip_adresa, klient_id, vraboten_id, banka_id, filijala_id)
SELECT (100000 + gs)::int,
       'Makedonija'::varchar(100),
       (ARRAY['Skopje','Bitola','Ohrid','Prilep','Tetovo','Kumanovo','Veles','Stip','Strumica','Gostivar'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Centar','Karposh','Aerodrom','Gazi Baba','Kisela Voda','Chair','Bitola','Ohrid','Prilep','Tetovo'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Debar Maalo','Kapistec','Karposh 1','Novo Lisiche','Avtokomanda','Bair','Varosh','Dva Bresta','Senjak','Bansko'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Partizanska','Ilindenska','Makedonija','Vodnjanska','Dame Gruev','Jane Sandanski','ASNOM','Goce Delcev','11 Oktomvri','Orce Nikolov','Boris Trajkovski','Krste Misirkov','Kuzman Josifovski Pitu'])[(gs % 13) + 1]::varchar(150),
       ((gs % 200) + 1)::text::varchar(20),
       ((gs % 40) + 1)::text::varchar(20),
       'VRABOTEN'::varchar(50),
       NULL::int,
       gs::int,
       NULL::int,
       NULL::int
FROM generate_series(1, 10000) AS gs;

-- ADRESA: banks
INSERT INTO adresa (adresa_id, drzava, grad, opstina, naselba, ulica, broj, stanben_broj, tip_adresa, klient_id, vraboten_id, banka_id, filijala_id)
SELECT (110000 + gs)::int,
       'Makedonija'::varchar(100),
       (ARRAY['Skopje','Bitola','Ohrid','Prilep','Tetovo','Kumanovo','Veles','Stip','Strumica','Gostivar'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Centar','Karposh','Aerodrom','Gazi Baba','Kisela Voda','Chair','Bitola','Ohrid','Prilep','Tetovo'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Debar Maalo','Kapistec','Karposh 1','Novo Lisiche','Avtokomanda','Bair','Varosh','Dva Bresta','Senjak','Bansko'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Partizanska','Ilindenska','Makedonija','Vodnjanska','Dame Gruev','Jane Sandanski','ASNOM','Goce Delcev','11 Oktomvri','Orce Nikolov','Boris Trajkovski','Krste Misirkov','Kuzman Josifovski Pitu'])[(gs % 13) + 1]::varchar(150),
       ((gs % 200) + 1)::text::varchar(20),
       ((gs % 40) + 1)::text::varchar(20),
       'BANKA'::varchar(50),
       NULL::int,
       NULL::int,
       gs::int,
       NULL::int
FROM generate_series(1, 10) AS gs;

-- ADRESA: branches
INSERT INTO adresa (adresa_id, drzava, grad, opstina, naselba, ulica, broj, stanben_broj, tip_adresa, klient_id, vraboten_id, banka_id, filijala_id)
SELECT (110010 + gs)::int,
       'Makedonija'::varchar(100),
       (ARRAY['Skopje','Bitola','Ohrid','Prilep','Tetovo','Kumanovo','Veles','Stip','Strumica','Gostivar'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Centar','Karposh','Aerodrom','Gazi Baba','Kisela Voda','Chair','Bitola','Ohrid','Prilep','Tetovo'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Debar Maalo','Kapistec','Karposh 1','Novo Lisiche','Avtokomanda','Bair','Varosh','Dva Bresta','Senjak','Bansko'])[(gs % 10) + 1]::varchar(100),
       (ARRAY['Partizanska','Ilindenska','Makedonija','Vodnjanska','Dame Gruev','Jane Sandanski','ASNOM','Goce Delcev','11 Oktomvri','Orce Nikolov','Boris Trajkovski','Krste Misirkov','Kuzman Josifovski Pitu'])[(gs % 13) + 1]::varchar(150),
       ((gs % 200) + 1)::text::varchar(20),
       ((gs % 40) + 1)::text::varchar(20),
       'FILIJALA'::varchar(50),
       NULL::int,
       NULL::int,
       NULL::int,
       gs::int
FROM generate_series(1, 100) AS gs;

-- ==========================================================
-- 6. SERVICES, CREDITS, CONTRACTS
-- ==========================================================

INSERT INTO usluga (usluga_id, ime, opis, datum_od, datum_do, tip_usluga, status, banka_id, filijala_id)
SELECT gs,
       'Usluga_' || gs,
       'Opis za usluga ' || gs,
       CURRENT_DATE - ((100 + floor(random() * 1900))::int),
       NULL,
       (ARRAY['SMETKA','KREDIT','DEPOZIT','KARTICKA','ONLINE_BANKING'])[(gs % 5) + 1],
       'AKTIVNA',
       ((((gs - 1) % 100)) % 10) + 1,
       ((gs - 1) % 100) + 1
FROM generate_series(1, 500) gs;

INSERT INTO tip_kredit (tip_kredit_id, tip, opis)
VALUES
    (1, 'Stanben kredit', 'Kredit za stan'),
    (2, 'Potrosuvacki kredit', 'Gotovinski kredit'),
    (3, 'Avto kredit', 'Kredit za vozilo'),
    (4, 'Studentski kredit', 'Kredit za studenti');

INSERT INTO kredit (kredit_id, kamatna_stapka, rok_otplata, iznos_kredit, mesecna_rata, tip_kredit_id, usluga_id, valuta_id)
WITH base AS (
    SELECT gs,
           round((500 + random() * 99500)::numeric, 2) AS principal,
           (ARRAY[12,24,36,48,60,84,120,240,360])[(floor(random()*9)::int)+1] AS months,
           round((2.5 + random() * 7)::numeric, 2) AS rate
    FROM generate_series(1, 50000) gs
)
SELECT gs,
       rate,
       months,
       principal,
       round((principal / months) * (1 + rate / 100), 2),
       ((gs - 1) % 4) + 1,
       ((gs - 1) % 500) + 1,
       ((gs - 1) % 5) + 1
FROM base;

INSERT INTO dogovor (dogovor_id, naslov, datum_kreiranje, datum_posledna_promena, datum_potpisuvanje, status, klient_id, banka_id, usluga_id, filijala_id)
WITH base AS (
    SELECT gs,
           CURRENT_DATE - (floor(random() * 2500)::int) AS created,
           (ARRAY['KREIRAN','POTPISAN','POTPISAN','POTPISAN','OTKAZAN','ISTECEN'])[(floor(random()*6)::int)+1] AS status,
           ((gs - 1) % 500) + 1 AS usluga_id,
           ((gs - 1) % 100) + 1 AS filijala_id
    FROM generate_series(1, 120000) gs
)
SELECT gs,
       'Dogovor za bankarska usluga - ' || EXTRACT(YEAR FROM created)::int || '/' || LPAD(gs::text, 6, '0'),
       created,
       created + (floor(random() * 30)::int),
       CASE WHEN status = 'KREIRAN' THEN NULL ELSE created + (floor(random() * 20)::int) END,
       status,
       ((gs - 1) % 100000) + 1,
       ((filijala_id - 1) % 10) + 1,
       usluga_id,
       filijala_id
FROM base;

INSERT INTO potpisnik (potpisnik_id, datum_potpisuvanje, klient_id, dogovor_id)
SELECT gs,
       CURRENT_DATE - (floor(random() * 2000)::int),
       ((gs - 1) % 100000) + 1,
       gs
FROM generate_series(1, 120000) gs;

-- ==========================================================
-- 7. ACCOUNTS, DEPOSITS AND CARDS
-- ==========================================================

INSERT INTO smetka (smetka_id, broj_smetka, datum_otvaranje, status, tip_smetka, usluga_id, klient_id, kredit_id, banka_id, valuta_id, saldo)
WITH base AS (
    SELECT gs,
           CASE
               WHEN random() < 0.62 THEN 'TEKOVNA'
               WHEN random() < 0.85 THEN 'DEVIZNA'
               ELSE 'STEDNA'
           END AS tip_smetka,
           CASE
               WHEN random() < 0.88 THEN 'AKTIVNA'
               WHEN random() < 0.96 THEN 'BLOKIRANA'
               ELSE 'ZATVORENA'
           END AS status
    FROM generate_series(1, 250000) gs
), enriched AS (
    SELECT gs,
           tip_smetka,
           status,
           CASE
               WHEN tip_smetka = 'TEKOVNA' THEN CASE WHEN random() < 0.92 THEN 1 ELSE 2 + floor(random()*4)::int END
               WHEN tip_smetka = 'DEVIZNA' THEN 2 + floor(random()*4)::int
               ELSE CASE WHEN random() < 0.65 THEN 1 ELSE 2 + floor(random()*4)::int END
           END AS valuta_id
    FROM base
)
SELECT gs,
       RIGHT('300000000000' || LPAD(gs::text, 8, '0'), 20),
       CURRENT_DATE - (floor(random() * 3000)::int),
       status,
       tip_smetka,
       ((gs - 1) % 500) + 1,
       ((gs - 1) % 100000) + 1,
       CASE WHEN gs % 5 = 0 THEN ((gs - 1) % 50000) + 1 ELSE NULL END,
       ((gs - 1) % 10) + 1,
       valuta_id,
       CASE
           WHEN status = 'ZATVORENA' THEN round((random() * 100)::numeric, 2)
           WHEN status = 'BLOKIRANA' AND random() < 0.25 THEN round((-100 - random() * 24900)::numeric, 2)
           WHEN tip_smetka = 'TEKOVNA' AND valuta_id = 1 THEN round((500 + random() * 349500)::numeric, 2)
           WHEN tip_smetka = 'TEKOVNA' THEN round((20 + random() * 7980)::numeric, 2)
           WHEN tip_smetka = 'DEVIZNA' THEN round((50 + random() * 29950)::numeric, 2)
           WHEN tip_smetka = 'STEDNA' AND valuta_id = 1 THEN round((10000 + random() * 1490000)::numeric, 2)
           ELSE round((200 + random() * 79800)::numeric, 2)
       END AS saldo
FROM enriched;

INSERT INTO depozit (depozit_id, iznos_depozit, rok_depozit, kamatna_stapka, datum_odobruvanje, datum_aktiviranje, momentalna_sostojba, tip_depozit, usluga_id, smetka_id, valuta_id)
WITH base AS (
    SELECT gs,
           round((100 + random() * 99900)::numeric, 2) AS dep,
           CURRENT_DATE - ((1 + floor(random() * 2000))::int) AS approved
    FROM generate_series(1, 70000) gs
)
SELECT gs,
       dep,
       (ARRAY[3,6,12,24,36,60])[(floor(random()*6)::int)+1],
       round((0.5 + random() * 5)::numeric, 2),
       approved,
       approved + (floor(random() * 10)::int),
       round((dep * (1.0 + random() * 0.2))::numeric, 2),
       (ARRAY['OROCEN','VIDEN','STEDEN'])[(gs % 3) + 1],
       ((gs - 1) % 500) + 1,
       ((gs - 1) % 250000) + 1,
       ((gs - 1) % 5) + 1
FROM base;

INSERT INTO tip_karticka (tip_karticka_id, ime, opis)
VALUES
    (1, 'Debitna', 'Debitna karticka'),
    (2, 'Kreditna', 'Kreditna karticka'),
    (3, 'Prepaid', 'Prepaid karticka');

INSERT INTO karticka (karticka_id, broj_karticka, datum_izdavanje, datum_istekuvanje, cvc_kod, status, smetka_id, tip_karticka_id)
WITH base AS (
    SELECT gs,
           CURRENT_DATE - (floor(random() * 1500)::int) AS issued
    FROM generate_series(1, 180000) gs
)
SELECT gs,
       RIGHT('4' || LPAD(gs::text, 15, '0'), 16),
       issued,
       issued + (365 * (ARRAY[3,4,5])[(floor(random()*3)::int)+1]),
       LPAD((gs % 1000)::text, 3, '0'),
       CASE WHEN gs % 100 = 0 THEN 'BLOKIRANA' ELSE 'AKTIVNA' END,
       ((gs - 1) % 250000) + 1,
       ((gs - 1) % 3) + 1
FROM base;

-- ==========================================================
-- 8. NOTIFICATIONS
-- ==========================================================

INSERT INTO izvestuvanje (izvestuvanje_id, naslov, poraka, datum_isprakjanje, klient_id, banka_id)
SELECT gs,
       (ARRAY[
           'Uspesna transakcija', 'Priliv na smetka', 'Potsetnik za rata', 'Nisko saldo',
           'Promena na kursna lista', 'Nova bankarska ponuda', 'Bezbednosno izvestuvanje',
           'Karticka pred istek', 'Blokirana karticka', 'Potpisuvanje dogovor',
           'Promena na status', 'Izvod dostapen'
       ])[(floor(random()*12)::int)+1],
       'Avtomatsko bankarsko izvestuvanje za klientot. Iznos: ' || round((100 + random()*150000)::numeric, 2)::text || ' MKD.',
       CURRENT_DATE - (floor(random() * 1000)::int),
       ((gs - 1) % 100000) + 1,
       ((gs - 1) % 10) + 1
FROM generate_series(1, 500000) gs;

-- ==========================================================
-- 9. PAYMENT ORDERS AND TRANSACTIONS
-- WARNING: These two are intentionally very large.
-- Change 20000000 to a smaller number while testing.
-- ==========================================================

INSERT INTO nalog (
    nalog_id, datum_na_valuta, povikuvanje_na_broj_odobruvanje, iznos,
    danocen_broj_embg, svrha_na_plakjanje, smetka_primalac_id, cel_na_doznaka,
    hitno, uplateno_mesto, smetka_na_budetski_korisnik_edinka_korisnik,
    prihodna_sifra, programa, nacin_plakjanje, nalogodavac_id,
    danocen_broj_primalac, smetka_nalogodavac_id, smetka_nalogoprimac_id,
    smetka_nalogoprimac, valuta_id, potpisnik_id
)
WITH base AS (
    SELECT gs,
           ((gs - 1) % 250000) + 1 AS from_acc,
           CASE WHEN (((gs) % 250000) + 1) = (((gs - 1) % 250000) + 1)
                THEN (((gs + 1) % 250000) + 1)
                ELSE (((gs) % 250000) + 1)
           END AS to_acc
    FROM generate_series(1, 20000000) gs
)
SELECT gs,
       CURRENT_DATE - (floor(random() * 1825)::int),
       'PB' || LPAD(gs::text, 10, '0'),
       round((10 + random() * 99990)::numeric, 2),
       RIGHT(LPAD((((from_acc - 1) % 100000) + 1)::text, 13, '0'), 13),
       (ARRAY['Plakjanje faktura','Prenos sredstva','Isplata','Uplata','E-commerce','Kirija','Komunalii'])[(gs % 7) + 1],
       to_acc,
       'Doznaka',
       CASE WHEN gs % 50 = 0 THEN true ELSE false END,
       (ARRAY['Skopje','Bitola','Ohrid','Prilep','Tetovo','Kumanovo','Veles','Stip','Strumica','Gostivar'])[(gs % 10) + 1],
       'BK' || LPAD((gs % 1000)::text, 4, '0'),
       'PS' || LPAD((gs % 999)::text, 3, '0'),
       'Programa_' || (gs % 20),
       (ARRAY['ELEKTRONSKI','SALDO','GOTOVINA'])[(floor(random()*3)::int)+1],
       ((from_acc - 1) % 100000) + 1,
       RIGHT(LPAD(to_acc::text, 13, '0'), 13),
       from_acc,
       to_acc,
       RIGHT('300000000000' || LPAD(to_acc::text, 8, '0'), 20),
       ((gs - 1) % 5) + 1,
       ((gs - 1) % 120000) + 1
FROM base;

INSERT INTO transakcija (transakcija_id, datum_na_valuta, iznos, datum_transakcija, opis, smetka_isprakjac_id, smetka_primac_id, nalog_id, valuta_id)
WITH base AS (
    SELECT gs,
           ((gs - 1) % 250000) + 1 AS from_acc,
           CASE WHEN (((gs) % 250000) + 1) = (((gs - 1) % 250000) + 1)
                THEN (((gs + 1) % 250000) + 1)
                ELSE (((gs) % 250000) + 1)
           END AS to_acc
    FROM generate_series(1, 20000000) gs
)
SELECT gs,
       CURRENT_DATE - (floor(random() * 1825)::int),
       round((10 + random() * 99990)::numeric, 2),
       (CURRENT_TIMESTAMP - ((floor(random() * 1825))::int * INTERVAL '1 day'))
           - ((floor(random() * 86400))::int * INTERVAL '1 second'),
       (ARRAY['Transfer','Online payment','ATM','POS','Internal transfer','Salary','Bill payment'])[(gs % 7) + 1],
       from_acc,
       to_acc,
       gs,
       ((gs - 1) % 5) + 1
FROM base;

INSERT INTO rata_kredit (rata_kredit_id, datum_na_valuta, status, iznos_rata, kredit_id, transakcija_id)
SELECT gs,
       CURRENT_DATE - (floor(random() * 1000)::int),
       (ARRAY['PLATENA','NEPLATENA','DOCNI'])[(gs % 3) + 1],
       round((50 + random() * 1450)::numeric, 2),
       ((gs - 1) % 50000) + 1,
       gs
FROM generate_series(1, 200000) gs;


-- ==========================================================
-- 11. SYNC SERIAL SEQUENCES AFTER EXPLICIT IDS
-- Important because this script inserts explicit primary-key values.
-- ==========================================================

SELECT setval(pg_get_serial_sequence('banka', 'banka_id'), COALESCE((SELECT MAX(banka_id) FROM banka), 1), true);
SELECT setval(pg_get_serial_sequence('valuta', 'valuta_id'), COALESCE((SELECT MAX(valuta_id) FROM valuta), 1), true);
SELECT setval(pg_get_serial_sequence('kursna_lista', 'kurs_id'), COALESCE((SELECT MAX(kurs_id) FROM kursna_lista), 1), true);
SELECT setval(pg_get_serial_sequence('bank_user', 'user_id'), COALESCE((SELECT MAX(user_id) FROM bank_user), 1), true);
SELECT setval(pg_get_serial_sequence('role', 'role_id'), COALESCE((SELECT MAX(role_id) FROM role), 1), true);
SELECT setval(pg_get_serial_sequence('privilegii', 'privilegija_id'), COALESCE((SELECT MAX(privilegija_id) FROM privilegii), 1), true);
SELECT setval(pg_get_serial_sequence('filijala', 'filijala_id'), COALESCE((SELECT MAX(filijala_id) FROM filijala), 1), true);
SELECT setval(pg_get_serial_sequence('klient', 'klient_id'), COALESCE((SELECT MAX(klient_id) FROM klient), 1), true);
SELECT setval(pg_get_serial_sequence('vraboten', 'vraboten_id'), COALESCE((SELECT MAX(vraboten_id) FROM vraboten), 1), true);
SELECT setval(pg_get_serial_sequence('telefon', 'telefon_id'), COALESCE((SELECT MAX(telefon_id) FROM telefon), 1), true);
SELECT setval(pg_get_serial_sequence('email', 'email_id'), COALESCE((SELECT MAX(email_id) FROM email), 1), true);
SELECT setval(pg_get_serial_sequence('adresa', 'adresa_id'), COALESCE((SELECT MAX(adresa_id) FROM adresa), 1), true);
SELECT setval(pg_get_serial_sequence('usluga', 'usluga_id'), COALESCE((SELECT MAX(usluga_id) FROM usluga), 1), true);
SELECT setval(pg_get_serial_sequence('tip_kredit', 'tip_kredit_id'), COALESCE((SELECT MAX(tip_kredit_id) FROM tip_kredit), 1), true);
SELECT setval(pg_get_serial_sequence('kredit', 'kredit_id'), COALESCE((SELECT MAX(kredit_id) FROM kredit), 1), true);
SELECT setval(pg_get_serial_sequence('dogovor', 'dogovor_id'), COALESCE((SELECT MAX(dogovor_id) FROM dogovor), 1), true);
SELECT setval(pg_get_serial_sequence('potpisnik', 'potpisnik_id'), COALESCE((SELECT MAX(potpisnik_id) FROM potpisnik), 1), true);
SELECT setval(pg_get_serial_sequence('smetka', 'smetka_id'), COALESCE((SELECT MAX(smetka_id) FROM smetka), 1), true);
SELECT setval(pg_get_serial_sequence('depozit', 'depozit_id'), COALESCE((SELECT MAX(depozit_id) FROM depozit), 1), true);
SELECT setval(pg_get_serial_sequence('tip_karticka', 'tip_karticka_id'), COALESCE((SELECT MAX(tip_karticka_id) FROM tip_karticka), 1), true);
SELECT setval(pg_get_serial_sequence('karticka', 'karticka_id'), COALESCE((SELECT MAX(karticka_id) FROM karticka), 1), true);
SELECT setval(pg_get_serial_sequence('izvestuvanje', 'izvestuvanje_id'), COALESCE((SELECT MAX(izvestuvanje_id) FROM izvestuvanje), 1), true);
SELECT setval(pg_get_serial_sequence('nalog', 'nalog_id'), COALESCE((SELECT MAX(nalog_id) FROM nalog), 1), true);
SELECT setval(pg_get_serial_sequence('transakcija', 'transakcija_id'), COALESCE((SELECT MAX(transakcija_id) FROM transakcija), 1), true);
SELECT setval(pg_get_serial_sequence('rata_kredit', 'rata_kredit_id'), COALESCE((SELECT MAX(rata_kredit_id) FROM rata_kredit), 1), true);

COMMIT;


-- 1. Сметки по клиент
CREATE INDEX idx_smetka_klient_id
ON smetka(klient_id);

-- 2. Сметка по валута
CREATE INDEX idx_smetka_valuta_id
ON smetka(valuta_id);

-- 3. Картички по сметка
CREATE INDEX idx_karticka_smetka_id
ON karticka(smetka_id);

-- 4. Картички по тип
CREATE INDEX idx_karticka_tip_karticka_id
ON karticka(tip_karticka_id);

-- 5. Рати по кредит
CREATE INDEX idx_rata_kredit_kredit_id
ON rata_kredit(kredit_id);

-- 6. Сметка по кредит
CREATE INDEX idx_smetka_kredit_id
ON smetka(kredit_id);

-- 7. Трансакции по испраќач
CREATE INDEX idx_transakcija_isprakjac
ON transakcija(smetka_isprakjac_id);

-- 8. Трансакции по примач
CREATE INDEX idx_transakcija_primac
ON transakcija(smetka_primac_id);

-- 9. Контакт информации по клиент
CREATE INDEX idx_telefon_klient_id
ON telefon(klient_id);

CREATE INDEX idx_email_klient_id
ON email(klient_id);

CREATE INDEX idx_adresa_klient_id
ON adresa(klient_id);

-- 10. Депозити по сметка
CREATE INDEX idx_depozit_smetka_id
ON depozit(smetka_id);

-- 11. Договори по клиент
CREATE INDEX idx_dogovor_klient_id
ON dogovor(klient_id);

-- 12. Договори по услуга
CREATE INDEX idx_dogovor_usluga_id
ON dogovor(usluga_id);

-- 13. Налози по налогодавач
CREATE INDEX idx_nalog_nalogodavac_id
ON nalog(nalogodavac_id);

-- 14. Налози по сметка налогодавач
CREATE INDEX idx_nalog_smetka_nalogodavac_id
ON nalog(smetka_nalogodavac_id);


SELECT *
FROM vw_smetki_detali
WHERE klient_id = 50000;

SELECT *
FROM vw_karticki_klienti_v2
WHERE klient_id = 50000;

SELECT *
FROM vw_kreditni_rati_status
WHERE klient_id = 50000;


-- FUNKCII

--plan za otplata na kredit
CREATE OR REPLACE FUNCTION fn_plan_otplata_kredit(
    p_iznos NUMERIC,
    p_kamatna_stapka NUMERIC,
    p_rok_otplata INT
)
RETURNS TABLE (
    mesec INT,
    rata NUMERIC,
    kamata NUMERIC,
    glavnica NUMERIC,
    preostanat_dolg NUMERIC
) AS
$$
DECLARE
    v_mesecna_kamata NUMERIC;
    v_rata NUMERIC;
    v_preostanat_dolg NUMERIC := p_iznos;
    v_kamata_mesec NUMERIC;
    v_glavnica NUMERIC;
    i INT;
BEGIN
    --mesecna kamata
    v_mesecna_kamata := (p_kamatna_stapka / 100) / 12;

    --fiksna rata
    IF v_mesecna_kamata = 0 THEN
        v_rata := ROUND(p_iznos / p_rok_otplata, 2);
    ELSE
        v_rata :=
            (p_iznos * v_mesecna_kamata) /
            (1 - POWER(1 + v_mesecna_kamata, -p_rok_otplata));
    END IF;

    --loop po meseci
    FOR i IN 1..p_rok_otplata LOOP

        v_kamata_mesec := ROUND(v_preostanat_dolg * v_mesecna_kamata, 2);
        v_glavnica := ROUND(v_rata - v_kamata_mesec, 2);
        v_preostanat_dolg := ROUND(v_preostanat_dolg - v_glavnica, 2);

        mesec := i;
        rata := v_rata;
        kamata := v_kamata_mesec;
        glavnica := v_glavnica;
        preostanat_dolg := GREATEST(v_preostanat_dolg, 0);

        RETURN NEXT;
    END LOOP;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_presmetaj_kamata_depozit(
    p_poceten_iznos NUMERIC,
    p_kamatna_stapka NUMERIC,
    p_broj_godini INT
)
RETURNS NUMERIC AS
$$
DECLARE
    v_krajna_suma NUMERIC;
BEGIN

    --compound interest
    v_krajna_suma :=
        p_poceten_iznos *
        POWER(1 + (p_kamatna_stapka / 100), p_broj_godini);

    RETURN ROUND(v_krajna_suma, 2);

END;
$$ LANGUAGE plpgsql;


--provizija vrz osnova na tipot na transakcija
CREATE OR REPLACE FUNCTION fn_presmetaj_provizija(
    p_iznos NUMERIC,
    p_tip_transakcija VARCHAR
)
RETURNS NUMERIC AS
$$
DECLARE
    v_provizija NUMERIC;
BEGIN

    IF p_tip_transakcija = 'DOMASNA' THEN
        v_provizija := p_iznos * 0.01;

    ELSIF p_tip_transakcija = 'MEGJUNARODNA' THEN
        v_provizija := p_iznos * 0.03;

    ELSE
        v_provizija := 0;
    END IF;

    --dodatna provizija za golemi sumi
    IF p_iznos > 100000 THEN
        v_provizija := v_provizija + 500;
    END IF;

    RETURN ROUND(v_provizija, 2);

END;
$$ LANGUAGE plpgsql;


-- PROCEDURI
--bankata naplakja odrzuvanje na smetki sekoj mesec
CREATE OR REPLACE PROCEDURE sp_mesecna_nadomestok_smetki()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    v_taksa NUMERIC := 50;
BEGIN

    FOR r IN
        SELECT smetka_id, saldo
        FROM smetka
        WHERE status = 'AKTIVNA'
    LOOP

        IF r.saldo >= v_taksa THEN
            UPDATE smetka
            SET saldo = saldo - v_taksa
            WHERE smetka_id = r.smetka_id;

        ELSE
            UPDATE smetka
            SET status = 'BLOKIRANA'
            WHERE smetka_id = r.smetka_id;
        END IF;

        INSERT INTO transakcija (
            datum_na_valuta,
            iznos,
            datum_transakcija,
            opis,
            smetka_isprakjac_id,
            smetka_primac_id,
            valuta_id
        )
        VALUES (
            CURRENT_DATE,
            v_taksa,
            NOW(),
            'Monthly fee',
            r.smetka_id,
            NULL,
            1
        );

    END LOOP;

END;
$$;

-- otvara nova smetka so 0 saldo
CREATE OR REPLACE PROCEDURE sp_otvori_smetka(
    p_tip_smetka VARCHAR,
    p_usluga_id INT,
    p_klient_id INT,
    p_banka_id INT,
    p_valuta_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_broj_smetka VARCHAR;
BEGIN

    -- генерира уникатен број на сметка
    v_broj_smetka :=
        'ACC-' || to_char(NOW(), 'YYYYMMDDHH24MISSMS') ||
        '-' || floor(random() * 1000);

    INSERT INTO smetka (
        broj_smetka,
        datum_otvaranje,
        status,
        tip_smetka,
        usluga_id,
        klient_id,
        banka_id,
        valuta_id,
        saldo
    )
    VALUES (
        LEFT(v_broj_smetka, 20),
        CURRENT_DATE,
        'AKTIVNA',
        p_tip_smetka,
        p_usluga_id,
        p_klient_id,
        p_banka_id,
        p_valuta_id,
        0
    );
END;
$$;


-- menuvanje status na karticka
CREATE OR REPLACE PROCEDURE sp_blokiraj_karticka(
    p_karticka_id INT
)
LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE karticka
    SET status = 'BLOKIRANA'
    WHERE karticka_id = p_karticka_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Kartickata ne postoi';
    END IF;
END;
$$;


--Trigeri

--triger 1
CREATE OR REPLACE FUNCTION fn_naplata_rata()
RETURNS TRIGGER AS
$$
DECLARE
    v_saldo NUMERIC;
    v_smetka_id INT;
BEGIN

    --najdi smetka so go koristi kreditot
    SELECT smetka_id
    INTO v_smetka_id
    FROM smetka
    WHERE kredit_id = NEW.kredit_id
    AND status='AKTIVNA'
    LIMIT 1;

    IF v_smetka_id IS NULL THEN
        RAISE EXCEPTION 'Nema smetka za ovoj kredit';
    END IF;


    SELECT saldo
    INTO v_saldo
    FROM smetka
    WHERE smetka_id = v_smetka_id;

    IF v_saldo < NEW.iznos_rata THEN
        NEW.status := 'NEPLATENA';
        RETURN NEW;
    END IF;

    UPDATE smetka
    SET saldo = saldo - NEW.iznos_rata
    WHERE smetka_id = v_smetka_id;


    NEW.status := 'PLATENA';

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_naplata_rata
BEFORE INSERT ON rata_kredit
FOR EACH ROW
EXECUTE FUNCTION fn_naplata_rata();



--triger 2
--proveruva dali kartickata e validna, blokirana i istecena
--ako e istecena sistemot avtomatski go azurira statusot i ja odbiva transakcijata
CREATE OR REPLACE FUNCTION fn_proveri_istecena_karticka()
RETURNS TRIGGER AS
$$
DECLARE
    v_karticka_id INT;
    v_datum_istekuvanje DATE;
    v_status_karticka VARCHAR(30);
BEGIN

    SELECT karticka_id, datum_istekuvanje, status
    INTO v_karticka_id, v_datum_istekuvanje, v_status_karticka
    FROM karticka
    WHERE smetka_id = NEW.smetka_isprakjac_id
    LIMIT 1;


    IF v_karticka_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- proverka na status
    IF v_status_karticka IN ('BLOKIRANA', 'ISTECENA') THEN
        RAISE EXCEPTION
        'Трансакцијата е одбиена. Картичката има статус: %',
        v_status_karticka;
    END IF;

    -- proverka na istekuvanje
    IF v_datum_istekuvanje IS NOT NULL AND v_datum_istekuvanje < CURRENT_DATE THEN

        UPDATE karticka
        SET status = 'ISTECENA'
        WHERE karticka_id = v_karticka_id;

        RAISE EXCEPTION
        'Трансакцијата е одбиена. Картичката е истечена (датум: %)',
        v_datum_istekuvanje;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_proveri_istecena_karticka
BEFORE INSERT ON transakcija
FOR EACH ROW
EXECUTE FUNCTION fn_proveri_istecena_karticka();



-- triger 3
--notifikacija po transakcija
CREATE OR REPLACE FUNCTION fn_transakcija_notification()
RETURNS TRIGGER AS
$$
DECLARE
    v_valuta VARCHAR;
    v_klient_id INT;
    v_banka_id INT;
    v_saldo NUMERIC;
BEGIN

    --valuta
    SELECT kod
    INTO v_valuta
    FROM valuta
    WHERE valuta_id = NEW.valuta_id;

    --podatoci od isprakjac
    SELECT klient_id, banka_id, saldo
    INTO v_klient_id, v_banka_id, v_saldo
    FROM smetka
    WHERE smetka_id = NEW.smetka_isprakjac_id;

    --proverka za saldo
    IF v_saldo < NEW.iznos THEN

        INSERT INTO izvestuvanje (
            naslov,
            poraka,
            klient_id,
            banka_id
        )
        VALUES (
            'Неуспешна трансакција',
            'Неуспешен обид за трансакција од ' ||
            NEW.iznos || ' ' || v_valuta,
            v_klient_id,
            v_banka_id
        );

        RAISE EXCEPTION 'Недоволно средства';

    END IF;

    --uspesna notifikacija
    INSERT INTO izvestuvanje (
        naslov,
        poraka,
        klient_id,
        banka_id
    )
    VALUES (
        'Успешна трансакција',
        'Испратени се ' || NEW.iznos || ' ' || v_valuta,
        v_klient_id,
        v_banka_id
    );

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_transakcija_notification
BEFORE INSERT ON transakcija
FOR EACH ROW
EXECUTE FUNCTION fn_transakcija_notification();

-- ============================================================
-- DATA WAREHOUSE SCHEMA FOR BANK SYSTEM
-- ============================================================

DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA dw;

-- ============================================================
-- DIMENSION: VREME
-- ============================================================

CREATE TABLE dw.dim_vreme (
    vreme_key INT PRIMARY KEY,
    datum DATE NOT NULL UNIQUE,
    den INT NOT NULL,
    mesec INT NOT NULL,
    kvartal INT NOT NULL,
    godina INT NOT NULL,
    ime_mesec VARCHAR(20),
    den_vo_nedela INT
);

-- ============================================================
-- DIMENSION: VALUTA
-- ============================================================

CREATE TABLE dw.dim_valuta (
    valuta_key SERIAL PRIMARY KEY,
    valuta_id INT NOT NULL UNIQUE,
    kod CHAR(3) NOT NULL,
    ime VARCHAR(100),
    simbol VARCHAR(5)
);

-- ============================================================
-- DIMENSION: KLIENT
-- Ова е основна верзија
-- ============================================================

CREATE TABLE dw.dim_klient (
    klient_key SERIAL PRIMARY KEY,
    klient_id INT NOT NULL UNIQUE,
    ime VARCHAR(100),
    prezime VARCHAR(100),
    datum_ragjanje DATE,
    embg CHAR(13),
    grad VARCHAR(100),
    opstina VARCHAR(100),
    naselba VARCHAR(100)
);

-- ============================================================
-- DIMENSION: BANKA
-- ============================================================

CREATE TABLE dw.dim_banka (
    banka_key SERIAL PRIMARY KEY,
    banka_id INT NOT NULL UNIQUE,
    ime_na_banka VARCHAR(100),
    edb VARCHAR(13),
    datum_na_osnovanje DATE
);

-- ============================================================
-- DIMENSION: SMETKA
-- ============================================================

CREATE TABLE dw.dim_smetka (
    smetka_key SERIAL PRIMARY KEY,
    smetka_id INT NOT NULL UNIQUE,
    broj_smetka VARCHAR(20),
    datum_otvaranje DATE,
    status VARCHAR(30),
    tip_smetka VARCHAR(100),
    klient_id INT,
    banka_id INT,
    valuta_id INT
);

-- ============================================================
-- FACT: TRANSAKCII
-- ============================================================

CREATE TABLE dw.fact_transakcii (
    fact_transakcija_key BIGSERIAL PRIMARY KEY,

    transakcija_id INT NOT NULL UNIQUE,

    vreme_key INT NOT NULL REFERENCES dw.dim_vreme(vreme_key),
    valuta_key INT NOT NULL REFERENCES dw.dim_valuta(valuta_key),

    isprakjac_smetka_key INT NOT NULL REFERENCES dw.dim_smetka(smetka_key),
    primac_smetka_key INT NOT NULL REFERENCES dw.dim_smetka(smetka_key),

    isprakjac_klient_key INT REFERENCES dw.dim_klient(klient_key),
    primac_klient_key INT REFERENCES dw.dim_klient(klient_key),

    iznos NUMERIC(15,2) NOT NULL,
    opis VARCHAR(255),

    datum_transakcija TIMESTAMP,
    datum_na_valuta DATE
);