use master
go
if exists(SELECT name FROM sys.databases WHERE name = 'dbEscolaTreinoSQL')
begin
	alter database dbEscolaTreinoSQL set single_user with rollback immediate;
    drop database dbEscolaTreinoSQL;
end
go
create database dbEscolaTreinoSQL
go
use dbEscolaTreinoSQL
go
set language 'portuguese'
go
-- TABELAS
create table nivel_ensino(
	id int primary key identity (1,1),
	nivel_ensino_nome varchar (45) not null,
)
go
create table serie_ensino(
	id int primary key identity (1,1),
	serie_nome varchar(20) not null,
	serie_numero int not null,
)
go
create table serie_nivel_ensino(
	serie_ensino_id int,
	nivel_ensino_id int,
	nome_relacao varchar(255) not null,
	primary key (serie_ensino_id, nivel_ensino_id),
	foreign key (serie_ensino_id) references serie_ensino(id),
	foreign key (nivel_ensino_id) references nivel_ensino(id),
)
go
create table escola(
	id int primary key identity (1,1),
	escola_nome varchar(255) not null,
)
go
create table escola_nivel_ensino(
	escola_id int,
	nivel_ensino_id int,
	primary key (escola_id, nivel_ensino_id),
	foreign key (escola_id) references escola(id),
	foreign key (nivel_ensino_id) references nivel_ensino(id),
)
go
create table turma(
	id int primary key identity (1,1),
	turma_nome varchar(25) not null,
	qtd_alunos int default 0 not null,
	escola_id int not null,
	serie_ensino_id int not null,
	nivel_ensino_id int not null,
	foreign key (escola_id) references escola(id),
	foreign key (serie_ensino_id, nivel_ensino_id) references serie_nivel_ensino(serie_ensino_id, nivel_ensino_id)
)
go
create table turma_auditoria(
	id int primary key identity (1,1),
	status_turma varchar(25) default 'Iniciada' check(status_turma in ('Iniciada', 'Em Andamento', 'Finalizada')) not null,
	qtd_alunos_atual int default 0 not null,
	ultimo_aluno int null,
	data_inicio_turma date default getdate(),
	data_fim_turma date null,
	turma_id int not null,
	foreign key (turma_id) references turma(id)
)
go
create table aluno(
	id int primary key identity (1,1),
	nome_completo varchar (max) not null,
	primeiro_nome varchar (255) not null,
	sobrenome varchar (255) not null,
	escola_id int not null,
	turma_ensino_id int not null,
	foreign key (escola_id) references escola(id),
	foreign key (turma_ensino_id) references turma(id)
)
go
create table aluno_auditoria(
	id int primary key identity (1,1),
	nome_completo varchar (max) not null,
	data_inicio_matricula date default getdate(),
	data_fim_matricula date null,
	nota_media decimal (2,2) null,
	nota_mais_baixa decimal (2,2) null,
	nota_mais_alta decimal (2,2) null,
	aluno_id int not null,
	escola_id int not null,
	turma_id int not null,
	foreign key (aluno_id) references aluno(id),
	foreign key (escola_id) references escola(id),
	foreign key (turma_id) references turma(id),
)
go
create table turma_aluno(
	aluno_id int,
	turma_id int,
	primary key (aluno_id, turma_id),
	foreign key (aluno_id) references aluno(id),
	foreign key (turma_id) references turma(id)
)
go
create table materia(
	id int primary key identity (1,1),
	nome varchar (255) not null,	
)
go
create table serie_nivel_ensino_materia(
	materia_id int not null,
	serie_ensino_id int not null,
	nivel_ensino_id int not null,
	primary key(materia_id, serie_ensino_id, nivel_ensino_id),
	foreign key (materia_id) references materia(id),
	foreign key (serie_ensino_id, nivel_ensino_id) references serie_nivel_ensino(serie_ensino_id, nivel_ensino_id)	
)
go
create table prova(
	id int primary key identity(1,1),
	assunto varchar(255) not null,
	nota decimal(2,2) default 10 not null,
	qtd_questoes int default 10 not null,
	materia_id int not null,
	foreign key (materia_id) references materia(id),
)
go
create table aluno_nota(
	nota decimal(2,2) not null,
	valor_prova decimal(2,2) default 10 not null,
	prova_id int,
	aluno_id int,
	nota_media decimal(2,2) not null,
	status_aluno varchar(25) not null,
	primary key (prova_id, aluno_id),
	foreign key (prova_id) references aluno(id),
	foreign key (aluno_id) references aluno(id),
)
go
-- TRIGGERS

go
-- PROCEDURES

go
-- INSERTS
insert into nivel_ensino values ('fundamental 1')
insert into nivel_ensino values ('fundamental 2')
insert into nivel_ensino values ('ensino médio')
go
insert into serie_ensino values ('primeiro ano', 1)
insert into serie_ensino values ('segundo ano', 2)
insert into serie_ensino values ('terceiro ano', 3)
insert into serie_ensino values ('quarto ano', 4)
insert into serie_ensino values ('quinto ano', 5)
insert into serie_ensino values ('sexto ano', 6)
insert into serie_ensino values ('sétimo ano', 7)
insert into serie_ensino values ('oitavo ano', 8)
insert into serie_ensino values ('nono ano', 9)
go
insert into materia values ('artes')
insert into materia values ('ciências')
insert into materia values ('educação física')
insert into materia values ('ensino religioso')
insert into materia values ('geografia')
insert into materia values ('história')
insert into materia values ('matemática')
insert into materia values ('língua inglesa')
insert into materia values ('língua portuguesa')
insert into materia values ('sociologia')
insert into materia values ('filosofia')
insert into materia values ('biologia')
insert into materia values ('química')
insert into materia values ('física')
insert into materia values ('literatura')
insert into materia values ('redação')