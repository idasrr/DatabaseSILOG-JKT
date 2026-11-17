-- =====================================================
-- TUGAS 9 - DB DESIGN & SQL : SILOG-JKT
-- Sistem Informasi Bantuan dan Distribusi Logistik DKI Jakarta
-- DBMS: MySQL 8 / MariaDB 10.x
-- =====================================================

-- 2. MEMBUAT DATABASE DAN TABEL
CREATE DATABASE silog_jkt;
USE silog_jkt;

CREATE TABLE bencana (
  id_bencana       VARCHAR(10)  NOT NULL,
  jenis            VARCHAR(40)  NOT NULL,
  tanggal_kejadian DATE         NOT NULL,
  wilayah          VARCHAR(40)  NOT NULL,
  status           ENUM('Aktif','Selesai') NOT NULL DEFAULT 'Aktif',
  keterangan       VARCHAR(255) NULL,
  PRIMARY KEY (id_bencana)
);

CREATE TABLE posko (
  id_posko   VARCHAR(10)  NOT NULL,
  nama       VARCHAR(60)  NOT NULL,
  alamat     VARCHAR(150) NOT NULL,
  wilayah    VARCHAR(40)  NOT NULL,
  kontak     VARCHAR(15)  NULL,
  status     ENUM('Aktif','Nonaktif') NOT NULL DEFAULT 'Aktif',
  id_bencana VARCHAR(10)  NOT NULL,
  PRIMARY KEY (id_posko),
  CONSTRAINT fk_posko_bencana FOREIGN KEY (id_bencana) REFERENCES bencana (id_bencana)
);

CREATE TABLE pengguna (
  id_pengguna   VARCHAR(10)  NOT NULL,
  nama_pengguna VARCHAR(30)  NOT NULL,
  kata_sandi    VARCHAR(255) NOT NULL,
  peran         ENUM('BPBD','POSKO') NOT NULL,
  id_posko      VARCHAR(10)  NULL,
  PRIMARY KEY (id_pengguna),
  UNIQUE KEY uq_nama_pengguna (nama_pengguna),
  CONSTRAINT fk_pengguna_posko FOREIGN KEY (id_posko) REFERENCES posko (id_posko),
  CONSTRAINT ck_pengguna_peran CHECK ((peran = 'POSKO' AND id_posko IS NOT NULL)
                                   OR (peran = 'BPBD'  AND id_posko IS NULL))
);

CREATE TABLE jenis_logistik (
  id_jenis VARCHAR(10) NOT NULL,
  nama     VARCHAR(50) NOT NULL,
  satuan   VARCHAR(15) NOT NULL,
  PRIMARY KEY (id_jenis),
  UNIQUE KEY uq_nama_jenis (nama)
);

CREATE TABLE bantuan_masuk (
  id_bantuan   VARCHAR(10)  NOT NULL,
  sumber       VARCHAR(60)  NOT NULL,
  tanggal_masuk DATE        NOT NULL,
  jumlah       INT UNSIGNED NOT NULL,
  id_jenis     VARCHAR(10)  NOT NULL,
  id_pengguna  VARCHAR(10)  NOT NULL,
  PRIMARY KEY (id_bantuan),
  CONSTRAINT fk_bm_jenis    FOREIGN KEY (id_jenis)    REFERENCES jenis_logistik (id_jenis),
  CONSTRAINT fk_bm_pengguna FOREIGN KEY (id_pengguna) REFERENCES pengguna (id_pengguna),
  CONSTRAINT ck_bm_jumlah   CHECK (jumlah > 0)
);

CREATE TABLE stok_gudang (
  id_stok  VARCHAR(10)  NOT NULL,
  id_jenis VARCHAR(10)  NOT NULL,
  jumlah   INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id_stok),
  UNIQUE KEY uq_stok_gudang_jenis (id_jenis),
  CONSTRAINT fk_sg_jenis FOREIGN KEY (id_jenis) REFERENCES jenis_logistik (id_jenis)
);

CREATE TABLE distribusi (
  id_distribusi   VARCHAR(10)  NOT NULL,
  id_bencana      VARCHAR(10)  NOT NULL,
  id_posko        VARCHAR(10)  NOT NULL,
  id_jenis        VARCHAR(10)  NOT NULL,
  id_pengguna     VARCHAR(10)  NOT NULL,
  jumlah          INT UNSIGNED NOT NULL,
  tanggal_kirim   DATE         NOT NULL,
  status          ENUM('Direncanakan','Dikirim','Diterima') NOT NULL DEFAULT 'Direncanakan',
  jumlah_diterima INT UNSIGNED NULL,
  tanggal_terima  DATE         NULL,
  catatan         VARCHAR(255) NULL,
  PRIMARY KEY (id_distribusi),
  CONSTRAINT fk_dst_bencana  FOREIGN KEY (id_bencana)  REFERENCES bencana (id_bencana),
  CONSTRAINT fk_dst_posko    FOREIGN KEY (id_posko)    REFERENCES posko (id_posko),
  CONSTRAINT fk_dst_jenis    FOREIGN KEY (id_jenis)    REFERENCES jenis_logistik (id_jenis),
  CONSTRAINT fk_dst_pengguna FOREIGN KEY (id_pengguna) REFERENCES pengguna (id_pengguna),
  CONSTRAINT ck_dst_jumlah   CHECK (jumlah > 0),
  CONSTRAINT ck_dst_terima   CHECK (status <> 'Diterima'
                                    OR (jumlah_diterima IS NOT NULL AND tanggal_terima IS NOT NULL)),
  CONSTRAINT ck_dst_tanggal  CHECK (tanggal_terima IS NULL OR tanggal_terima >= tanggal_kirim)
);

CREATE TABLE kebutuhan_logistik (
  id_kebutuhan     VARCHAR(10)  NOT NULL,
  id_posko         VARCHAR(10)  NOT NULL,
  id_jenis         VARCHAR(10)  NOT NULL,
  jumlah_dibutuhkan INT UNSIGNED NOT NULL,
  tanggal          DATE         NOT NULL,
  PRIMARY KEY (id_kebutuhan),
  UNIQUE KEY uq_kebutuhan_posko_jenis (id_posko, id_jenis),
  CONSTRAINT fk_kb_posko FOREIGN KEY (id_posko) REFERENCES posko (id_posko),
  CONSTRAINT fk_kb_jenis FOREIGN KEY (id_jenis) REFERENCES jenis_logistik (id_jenis),
  CONSTRAINT ck_kb_jumlah CHECK (jumlah_dibutuhkan > 0)
);

CREATE TABLE stok_posko (
  id_stok           VARCHAR(10)  NOT NULL,
  id_posko          VARCHAR(10)  NOT NULL,
  id_jenis          VARCHAR(10)  NOT NULL,
  jumlah            INT UNSIGNED NOT NULL DEFAULT 0,
  tanggal_pembaruan DATETIME     NOT NULL,
  PRIMARY KEY (id_stok),
  UNIQUE KEY uq_stok_posko_jenis (id_posko, id_jenis),
  CONSTRAINT fk_sp_posko FOREIGN KEY (id_posko) REFERENCES posko (id_posko),
  CONSTRAINT fk_sp_jenis FOREIGN KEY (id_jenis) REFERENCES jenis_logistik (id_jenis)
);

CREATE TABLE log_audit (
  id_log        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_pengguna   VARCHAR(10)  NOT NULL,
  waktu         DATETIME     NOT NULL,
  data_terkait  VARCHAR(100) NOT NULL,
  nilai_sebelum VARCHAR(255) NULL,
  nilai_sesudah VARCHAR(255) NULL,
  PRIMARY KEY (id_log),
  CONSTRAINT fk_log_pengguna FOREIGN KEY (id_pengguna) REFERENCES pengguna (id_pengguna)
);

-- 3. MENGISI DATA (DATA DUMMY, PERIODE 1 AGUSTUS - 31 OKTOBER 2026)
INSERT INTO bencana VALUES
('BNC01','Kebakaran Permukiman','2026-08-04','Jakarta Barat','Selesai','Kebakaran di permukiman padat penduduk'),
('BNC02','Angin Kencang','2026-08-23','Jakarta Selatan','Selesai','Rumah warga rusak akibat angin kencang'),
('BNC03','Banjir Rob','2026-09-12','Jakarta Utara','Aktif','Air laut pasang menggenangi permukiman pesisir'),
('BNC04','Kebakaran Permukiman','2026-09-30','Jakarta Timur','Selesai','Kebakaran di permukiman padat penduduk'),
('BNC05','Banjir Luapan Kali','2026-10-18','Jakarta Timur','Aktif','Luapan sungai merendam permukiman bantaran');

INSERT INTO posko VALUES
('PSK01','Posko Cengkareng','Jl. Kapuk Raya No. 12, Cengkareng','Jakarta Barat','081200000001','Nonaktif','BNC01'),
('PSK02','Posko Kalideres','Jl. Daan Mogot Km 14, Kalideres','Jakarta Barat','081200000002','Nonaktif','BNC01'),
('PSK03','Posko Pasar Minggu','Jl. Raya Pasar Minggu No. 40','Jakarta Selatan','081200000003','Nonaktif','BNC02'),
('PSK04','Posko Penjaringan','Jl. Pluit Raya No. 5, Penjaringan','Jakarta Utara','081200000004','Aktif','BNC03'),
('PSK05','Posko Cakung','Jl. Raya Bekasi Km 22, Cakung','Jakarta Timur','081200000005','Nonaktif','BNC04'),
('PSK06','Posko Kampung Melayu','Jl. Jatinegara Barat No. 8','Jakarta Timur','081200000006','Aktif','BNC05'),
('PSK07','Posko Jatinegara','Jl. Jatinegara Timur No. 21','Jakarta Timur','081200000007','Aktif','BNC05');

INSERT INTO pengguna VALUES
('USR01','bpbd_andi',   SHA2('sandi_bpbd_andi',256),   'BPBD',  NULL),
('USR02','bpbd_sinta',  SHA2('sandi_bpbd_sinta',256),  'BPBD',  NULL),
('USR03','posko_cgkr',  SHA2('sandi_posko_cgkr',256),  'POSKO', 'PSK01'),
('USR04','posko_pjrg',  SHA2('sandi_posko_pjrg',256),  'POSKO', 'PSK04'),
('USR05','posko_kpmly', SHA2('sandi_posko_kpmly',256), 'POSKO', 'PSK06'),
('USR06','posko_jtng',  SHA2('sandi_posko_jtng',256),  'POSKO', 'PSK07');

INSERT INTO jenis_logistik VALUES
('JNS01','Beras','kg'),
('JNS02','Air Mineral','dus'),
('JNS03','Mi Instan','dus'),
('JNS04','Selimut','lembar'),
('JNS05','Paket Kebersihan','paket'),
('JNS06','Terpal','lembar');

INSERT INTO bantuan_masuk VALUES
('BM001','PT Sumber Pangan Nusantara','2026-08-01',1500,'JNS01','USR01'),
('BM002','Yayasan Peduli Jakarta','2026-08-01',600,'JNS02','USR01'),
('BM003','PMI DKI Jakarta','2026-08-02',400,'JNS03','USR02'),
('BM004','Kementerian Sosial','2026-08-02',500,'JNS04','USR02'),
('BM005','Donatur Perorangan','2026-08-03',250,'JNS05','USR01'),
('BM006','Dinas Sosial DKI','2026-08-03',150,'JNS06','USR02'),
('BM007','Koperasi Warga Sejahtera','2026-08-18',800,'JNS01','USR01'),
('BM008','PT Aqua Sejuk Abadi','2026-08-18',500,'JNS02','USR02'),
('BM009','Komunitas Berbagi Jakarta','2026-08-20',300,'JNS03','USR01'),
('BM010','Donatur Perorangan','2026-08-22',400,'JNS04','USR02'),
('BM011','Yayasan Peduli Jakarta','2026-09-05',250,'JNS05','USR01'),
('BM012','PT Sumber Pangan Nusantara','2026-09-08',1000,'JNS01','USR01'),
('BM013','PMI DKI Jakarta','2026-09-09',400,'JNS02','USR02'),
('BM014','Kementerian Sosial','2026-09-10',400,'JNS04','USR01'),
('BM015','Dinas Sosial DKI','2026-09-10',130,'JNS06','USR02'),
('BM016','Komunitas Berbagi Jakarta','2026-09-18',350,'JNS03','USR02'),
('BM017','Donatur Perorangan','2026-09-24',200,'JNS05','USR01'),
('BM018','Koperasi Warga Sejahtera','2026-09-25',600,'JNS01','USR02'),
('BM019','PT Aqua Sejuk Abadi','2026-09-29',300,'JNS02','USR01'),
('BM020','PT Sumber Pangan Nusantara','2026-10-10',300,'JNS01','USR01'),
('BM021','PMI DKI Jakarta','2026-10-12',250,'JNS03','USR02'),
('BM022','Kementerian Sosial','2026-10-14',600,'JNS04','USR01'),
('BM023','Dinas Sosial DKI','2026-10-15',120,'JNS06','USR02'),
('BM024','Yayasan Peduli Jakarta','2026-10-17',100,'JNS05','USR01');

-- Stok gudang = total bantuan masuk - total distribusi berstatus Dikirim/Diterima
INSERT INTO stok_gudang VALUES
('STG01','JNS01',650),
('STG02','JNS02',360),
('STG03','JNS03',300),
('STG04','JNS04',700),
('STG05','JNS05',250),
('STG06','JNS06',140);

INSERT INTO distribusi VALUES
('DST001','BNC01','PSK01','JNS01','USR01',500,'2026-08-05','Diterima',500,'2026-08-06',NULL),
('DST002','BNC01','PSK01','JNS02','USR01',200,'2026-08-05','Diterima',200,'2026-08-06',NULL),
('DST003','BNC01','PSK01','JNS03','USR01',150,'2026-08-06','Diterima',150,'2026-08-07',NULL),
('DST004','BNC01','PSK02','JNS01','USR01',400,'2026-08-06','Diterima',395,'2026-08-07','Kantong sobek, 5 kg tumpah'),
('DST005','BNC01','PSK02','JNS04','USR02',300,'2026-08-07','Diterima',300,'2026-08-08',NULL),
('DST006','BNC01','PSK01','JNS05','USR02',100,'2026-08-09','Diterima',100,'2026-08-10',NULL),
('DST007','BNC01','PSK02','JNS06','USR02',80,'2026-08-10','Diterima',80,'2026-08-11',NULL),
('DST008','BNC02','PSK03','JNS01','USR01',350,'2026-08-24','Diterima',350,'2026-08-25',NULL),
('DST009','BNC02','PSK03','JNS02','USR01',150,'2026-08-24','Diterima',150,'2026-08-25',NULL),
('DST010','BNC02','PSK03','JNS03','USR02',120,'2026-08-25','Diterima',118,'2026-08-26','2 dus rusak'),
('DST011','BNC02','PSK03','JNS04','USR02',200,'2026-08-26','Diterima',200,'2026-08-27',NULL),
('DST012','BNC02','PSK03','JNS05','USR01',80,'2026-08-28','Diterima',80,'2026-08-29',NULL),
('DST013','BNC03','PSK04','JNS01','USR01',600,'2026-09-13','Diterima',600,'2026-09-14',NULL),
('DST014','BNC03','PSK04','JNS02','USR01',300,'2026-09-13','Diterima',300,'2026-09-14',NULL),
('DST015','BNC03','PSK04','JNS03','USR02',250,'2026-09-14','Diterima',250,'2026-09-15',NULL),
('DST016','BNC03','PSK04','JNS04','USR02',250,'2026-09-15','Diterima',250,'2026-09-16',NULL),
('DST017','BNC03','PSK04','JNS06','USR01',120,'2026-09-16','Diterima',118,'2026-09-17','2 lembar sobek'),
('DST018','BNC03','PSK04','JNS05','USR01',150,'2026-09-20','Diterima',150,'2026-09-21',NULL),
('DST019','BNC03','PSK04','JNS01','USR02',450,'2026-09-27','Diterima',450,'2026-09-28',NULL),
('DST020','BNC03','PSK04','JNS02','USR02',200,'2026-10-04','Diterima',200,'2026-10-05',NULL),
('DST021','BNC04','PSK05','JNS01','USR01',300,'2026-10-01','Diterima',300,'2026-10-02',NULL),
('DST022','BNC04','PSK05','JNS02','USR01',120,'2026-10-01','Diterima',120,'2026-10-02',NULL),
('DST023','BNC04','PSK05','JNS03','USR02',100,'2026-10-02','Diterima',100,'2026-10-03',NULL),
('DST024','BNC04','PSK05','JNS04','USR02',150,'2026-10-03','Diterima',150,'2026-10-04',NULL),
('DST025','BNC04','PSK05','JNS06','USR01',60,'2026-10-05','Diterima',60,'2026-10-06',NULL),
('DST026','BNC05','PSK06','JNS01','USR01',500,'2026-10-19','Diterima',500,'2026-10-20',NULL),
('DST027','BNC05','PSK06','JNS02','USR01',250,'2026-10-19','Diterima',250,'2026-10-20',NULL),
('DST028','BNC05','PSK07','JNS01','USR02',450,'2026-10-20','Diterima',445,'2026-10-21','5 kg tumpah saat pengangkutan'),
('DST029','BNC05','PSK07','JNS03','USR02',200,'2026-10-21','Diterima',200,'2026-10-22',NULL),
('DST030','BNC05','PSK06','JNS04','USR01',300,'2026-10-22','Diterima',300,'2026-10-23',NULL),
('DST031','BNC05','PSK07','JNS05','USR02',120,'2026-10-24','Diterima',120,'2026-10-25',NULL),
('DST032','BNC05','PSK06','JNS03','USR01',180,'2026-10-26','Diterima',180,'2026-10-27',NULL),
('DST033','BNC05','PSK07','JNS02','USR02',220,'2026-10-28','Dikirim',NULL,NULL,NULL),
('DST034','BNC05','PSK06','JNS05','USR01',100,'2026-10-29','Dikirim',NULL,NULL,NULL),
('DST035','BNC05','PSK07','JNS04','USR02',250,'2026-10-30','Direncanakan',NULL,NULL,NULL),
('DST036','BNC05','PSK06','JNS06','USR01',90,'2026-10-31','Direncanakan',NULL,NULL,NULL);

INSERT INTO kebutuhan_logistik VALUES
('KBT01','PSK04','JNS01',800,'2026-10-28'),
('KBT02','PSK04','JNS02',400,'2026-10-28'),
('KBT03','PSK04','JNS04',300,'2026-10-28'),
('KBT04','PSK04','JNS06',200,'2026-10-28'),
('KBT05','PSK06','JNS01',700,'2026-10-29'),
('KBT06','PSK06','JNS02',400,'2026-10-29'),
('KBT07','PSK06','JNS03',300,'2026-10-29'),
('KBT08','PSK06','JNS04',450,'2026-10-29'),
('KBT09','PSK06','JNS05',250,'2026-10-29'),
('KBT10','PSK07','JNS01',650,'2026-10-29'),
('KBT11','PSK07','JNS02',500,'2026-10-29'),
('KBT12','PSK07','JNS03',300,'2026-10-29'),
('KBT13','PSK07','JNS04',400,'2026-10-29'),
('KBT14','PSK07','JNS05',200,'2026-10-29'),
('KBT15','PSK05','JNS06',100,'2026-10-04');

INSERT INTO stok_posko VALUES
('STP01','PSK04','JNS01',520,'2026-10-31 09:00:00'),
('STP02','PSK04','JNS02',150,'2026-10-31 09:00:00'),
('STP03','PSK04','JNS04',120,'2026-10-31 09:00:00'),
('STP04','PSK04','JNS06',40,'2026-10-31 09:00:00'),
('STP05','PSK06','JNS01',380,'2026-10-31 10:15:00'),
('STP06','PSK06','JNS02',180,'2026-10-31 10:15:00'),
('STP07','PSK06','JNS03',150,'2026-10-31 10:15:00'),
('STP08','PSK06','JNS04',160,'2026-10-31 10:15:00'),
('STP09','PSK06','JNS05',60,'2026-10-31 10:15:00'),
('STP10','PSK07','JNS01',300,'2026-10-31 11:30:00'),
('STP11','PSK07','JNS02',90,'2026-10-31 11:30:00'),
('STP12','PSK07','JNS03',100,'2026-10-31 11:30:00'),
('STP13','PSK07','JNS04',80,'2026-10-31 11:30:00'),
('STP14','PSK07','JNS05',70,'2026-10-31 11:30:00'),
('STP15','PSK05','JNS06',70,'2026-10-06 14:00:00');

INSERT INTO log_audit (id_pengguna, waktu, data_terkait, nilai_sebelum, nilai_sesudah) VALUES
('USR01','2026-10-19 08:15:00','distribusi DST026','status=Direncanakan','status=Dikirim'),
('USR05','2026-10-20 13:40:00','distribusi DST026','status=Dikirim','status=Diterima'),
('USR02','2026-10-20 09:05:00','distribusi DST028','status=Direncanakan','status=Dikirim'),
('USR06','2026-10-21 15:20:00','distribusi DST028','status=Dikirim; jumlah_diterima=NULL','status=Diterima; jumlah_diterima=445'),
('USR01','2026-10-17 10:00:00','bantuan_masuk BM024','-','jumlah=100'),
('USR05','2026-10-31 10:15:00','stok_posko STP05','jumlah=330','jumlah=380');

-- 4. QUERY SQL (SELECT - FROM - WHERE)
-- 4.1 Bencana yang berstatus Aktif
SELECT id_bencana, jenis, tanggal_kejadian, wilayah
FROM bencana
WHERE status = 'Aktif';

-- 4.2 Posko aktif beserta bencana yang dilayani
SELECT p.nama AS posko, p.wilayah, b.jenis AS bencana
FROM posko p
JOIN bencana b ON b.id_bencana = p.id_bencana
WHERE p.status = 'Aktif';

-- 4.3 Bantuan masuk pada bulan September 2026
SELECT m.id_bantuan, m.sumber, m.tanggal_masuk, j.nama AS logistik, m.jumlah, j.satuan
FROM bantuan_masuk m
JOIN jenis_logistik j ON j.id_jenis = m.id_jenis
WHERE m.tanggal_masuk BETWEEN '2026-09-01' AND '2026-09-30'
ORDER BY m.tanggal_masuk;

-- 4.4 Bantuan dari sumber yang namanya mengandung "Peduli" atau "PMI"
SELECT id_bantuan, sumber, tanggal_masuk, jumlah
FROM bantuan_masuk
WHERE sumber LIKE '%Peduli%' OR sumber LIKE 'PMI%';

-- 4.5 Distribusi berstatus Dikirim yang menunggu konfirmasi posko
SELECT d.id_distribusi, p.nama AS posko_tujuan, j.nama AS logistik, d.jumlah, d.tanggal_kirim
FROM distribusi d
JOIN posko p ON p.id_posko = d.id_posko
JOIN jenis_logistik j ON j.id_jenis = d.id_jenis
WHERE d.status = 'Dikirim';

-- 4.6 Distribusi yang jumlah diterimanya berbeda dari jumlah dikirim (selisih)
SELECT id_distribusi, id_posko, id_jenis, jumlah, jumlah_diterima,
       (jumlah - jumlah_diterima) AS selisih, catatan
FROM distribusi
WHERE status = 'Diterima' AND jumlah_diterima <> jumlah;

-- 4.7 Kebutuhan donasi: kebutuhan posko aktif yang melebihi stok posko
SELECT p.nama AS posko, j.nama AS logistik,
       k.jumlah_dibutuhkan, s.jumlah AS stok,
       (k.jumlah_dibutuhkan - s.jumlah) AS kekurangan
FROM kebutuhan_logistik k
JOIN stok_posko s ON s.id_posko = k.id_posko AND s.id_jenis = k.id_jenis
JOIN posko p ON p.id_posko = k.id_posko
JOIN jenis_logistik j ON j.id_jenis = k.id_jenis
WHERE p.status = 'Aktif' AND k.jumlah_dibutuhkan > s.jumlah
ORDER BY kekurangan DESC;

-- 4.8 Stok gudang BPBD yang kurang dari 400
SELECT j.nama AS logistik, g.jumlah AS stok_gudang, j.satuan
FROM stok_gudang g
JOIN jenis_logistik j ON j.id_jenis = g.id_jenis
WHERE g.jumlah < 400
ORDER BY g.jumlah;

-- 5. QUERY ANALITIK (GROUP BY - HAVING)
-- 5.1 Total bantuan masuk per jenis logistik (hanya yang lebih dari 1000)
SELECT j.nama AS logistik, SUM(m.jumlah) AS total_masuk, j.satuan
FROM bantuan_masuk m
JOIN jenis_logistik j ON j.id_jenis = m.id_jenis
GROUP BY j.id_jenis, j.nama, j.satuan
HAVING SUM(m.jumlah) > 1000
ORDER BY total_masuk DESC;

-- 5.2 Jumlah distribusi dan total jumlah dikirim per bulan
SELECT DATE_FORMAT(tanggal_kirim, '%Y-%m') AS bulan,
       COUNT(*) AS jumlah_distribusi,
       SUM(jumlah) AS total_dikirim
FROM distribusi
GROUP BY DATE_FORMAT(tanggal_kirim, '%Y-%m')
ORDER BY bulan;

-- 5.3 Posko dengan 5 distribusi atau lebih
SELECT p.nama AS posko, COUNT(*) AS jumlah_distribusi
FROM distribusi d
JOIN posko p ON p.id_posko = d.id_posko
GROUP BY p.id_posko, p.nama
HAVING COUNT(*) >= 5
ORDER BY jumlah_distribusi DESC;

-- 5.4 Donatur atau sumber dengan total bantuan 1000 atau lebih
SELECT sumber, COUNT(*) AS kali_menyumbang, SUM(jumlah) AS total_jumlah
FROM bantuan_masuk
GROUP BY sumber
HAVING SUM(jumlah) >= 1000
ORDER BY total_jumlah DESC;

-- 5.5 Rekap distribusi per bencana (hanya yang berstatus Diterima, minimal 5 kali)
SELECT b.jenis AS bencana, b.tanggal_kejadian, COUNT(*) AS jumlah_distribusi,
       SUM(d.jumlah_diterima) AS total_diterima
FROM distribusi d
JOIN bencana b ON b.id_bencana = d.id_bencana
WHERE d.status = 'Diterima'
GROUP BY b.id_bencana, b.jenis, b.tanggal_kejadian
HAVING COUNT(*) >= 5
ORDER BY b.tanggal_kejadian;

-- 5.6 Posko aktif dengan total kekurangan logistik lebih dari 500 unit
SELECT p.nama AS posko, SUM(k.jumlah_dibutuhkan - s.jumlah) AS total_kekurangan
FROM kebutuhan_logistik k
JOIN stok_posko s ON s.id_posko = k.id_posko AND s.id_jenis = k.id_jenis
JOIN posko p ON p.id_posko = k.id_posko
WHERE p.status = 'Aktif' AND k.jumlah_dibutuhkan > s.jumlah
GROUP BY p.id_posko, p.nama
HAVING SUM(k.jumlah_dibutuhkan - s.jumlah) > 500
ORDER BY total_kekurangan DESC;

-- 5.7 Total selisih bantuan (dikirim - diterima) per jenis logistik
SELECT j.nama AS logistik, SUM(d.jumlah - d.jumlah_diterima) AS total_selisih
FROM distribusi d
JOIN jenis_logistik j ON j.id_jenis = d.id_jenis
WHERE d.status = 'Diterima'
GROUP BY j.id_jenis, j.nama
HAVING SUM(d.jumlah - d.jumlah_diterima) > 0;

-- 5.8 Pemeriksaan konsistensi: stok gudang = bantuan masuk - distribusi (Dikirim/Diterima)
SELECT j.nama AS logistik,
       COALESCE(m.total_masuk,0) AS total_masuk,
       COALESCE(d.total_keluar,0) AS total_keluar,
       COALESCE(m.total_masuk,0) - COALESCE(d.total_keluar,0) AS stok_hitung,
       g.jumlah AS stok_tercatat
FROM jenis_logistik j
JOIN stok_gudang g ON g.id_jenis = j.id_jenis
LEFT JOIN (SELECT id_jenis, SUM(jumlah) AS total_masuk FROM bantuan_masuk GROUP BY id_jenis) m
       ON m.id_jenis = j.id_jenis
LEFT JOIN (SELECT id_jenis, SUM(jumlah) AS total_keluar FROM distribusi
           WHERE status IN ('Dikirim','Diterima') GROUP BY id_jenis) d
       ON d.id_jenis = j.id_jenis;
