-- =============================================================================
-- DDL - Library API (Azure SQL Database / SQL Server)
--
-- t_autor 1 ──── N t_livro
-- Cada livro pertence a um autor (t_livro.autor_id -> t_autor.id)
--
-- Executar no Query Editor do Azure SQL Database (portal) ou no Azure Data Studio.
-- =============================================================================

-- Remove na ordem inversa da dependência (a tabela com a FK sai primeiro)
DROP TABLE IF EXISTS t_livro;
DROP TABLE IF EXISTS t_autor;

CREATE TABLE t_autor (
                         id             BIGINT IDENTITY(1,1) NOT NULL,
                         nome           VARCHAR(255)         NOT NULL,
                         nacionalidade  VARCHAR(255)         NULL,
                         CONSTRAINT pk_t_autor PRIMARY KEY (id)
);

CREATE TABLE t_livro (
                         id              BIGINT IDENTITY(1,1) NOT NULL,
                         titulo          VARCHAR(255)         NOT NULL,
                         ano_publicacao  INT                  NULL,
                         autor_id        BIGINT               NOT NULL,
                         CONSTRAINT pk_t_livro PRIMARY KEY (id),
                         CONSTRAINT fk_t_livro_t_autor FOREIGN KEY (autor_id) REFERENCES t_autor (id)
);

CREATE INDEX ix_t_livro_autor_id ON t_livro (autor_id);