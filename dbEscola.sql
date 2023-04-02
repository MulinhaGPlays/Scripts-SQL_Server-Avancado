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
	nome_relacao varchar(255) null,
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
	status_turma varchar(25) default 'Iniciada' check(status_turma in ('Iniciada', 'Em Andamento', 'Finalizada')) not null,
	qtd_alunos_atual int default 0 not null,
	ultimo_aluno varchar(255) null,
	data_inicio_turma date default getdate(),
	data_fim_turma date null,
	turma_id int not null,
	primary key (turma_id),
	foreign key (turma_id) references turma(id)
)
go
create table aluno(
	id int primary key identity (1,1),
	nome_completo varchar (max) null,
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
	prova_id int,
	aluno_id int,
	primary key (prova_id, aluno_id),
	foreign key (prova_id) references aluno(id),
	foreign key (aluno_id) references aluno(id),
)
go
-- TRIGGERS
create trigger nome_relacao_serie_nivel_ensino
on serie_nivel_ensino
instead of insert
as
begin
	insert into serie_nivel_ensino
		select i.serie_ensino_id, i.nivel_ensino_id, (s.serie_nome + ' do ' + n.nivel_ensino_nome)
			from inserted i 
				inner join serie_ensino s on s.id = i.serie_ensino_id 
				inner join nivel_ensino n on n.id = i.nivel_ensino_id;
end;
go
create trigger nome_completo_aluno
on aluno
instead of insert
as
begin
	insert into aluno
		select (i.primeiro_nome + ' ' + i.sobrenome), i.primeiro_nome, i.sobrenome, i.escola_id, i.turma_ensino_id
			from inserted i 
end;
go
create trigger tracking_aluno
on aluno
after insert, delete
as
begin
declare @tipo_operacao varchar(45)

select @tipo_operacao =
	case 
		when exists(select * from inserted) then 'insert'
		when exists(select * from deleted) then 'delete'
	end
if (@tipo_operacao = 'insert')
begin
	insert into aluno_auditoria (data_inicio_matricula, turma_id, escola_id, aluno_id) 
		select getdate(), i.turma_ensino_id, i.escola_id, i.id from inserted i
end
else if (@tipo_operacao = 'delete')
begin
	update aluno_auditoria set data_fim_matricula = getdate()
end
end
go
create trigger tracking_turma
on turma
after insert, delete
as
begin
declare @tipo_operacao varchar(45)

select @tipo_operacao =
	case 
		when exists(select * from inserted) then 'Iniciada'
		when exists(select * from deleted) then 'Finalizada'
	end
if (@tipo_operacao = 'Iniciada')
begin
	insert into turma_auditoria (status_turma, turma_id) select @tipo_operacao, (select i.id from inserted i)
end
else if (@tipo_operacao = 'Finalizada')
begin
	update turma_auditoria set status_turma = 'Finalizada', data_fim_turma = getdate() where turma_id = (select d.id from deleted d)
end
end
go
create trigger tracking_turma_aluno
on turma_aluno
after insert, update
as
begin
declare @nome_ultimo_aluno varchar(255), @qtd_alunos int

select @qtd_alunos = (select count(*) from turma_aluno where turma_id = (select i.turma_id from inserted i))
select @nome_ultimo_aluno = (select nome_completo from aluno where id = (select scope_identity() from turma_aluno where turma_id = (select i.turma_id from inserted i)))

update turma_auditoria 
	set 
		status_turma = 'Em Andamento',
		qtd_alunos_atual = @qtd_alunos,
		ultimo_aluno = @nome_ultimo_aluno
	where turma_id = (select i.turma_id from inserted i)
end
go
create trigger tracking_aluno_nota
on aluno_nota
after insert, update
as
begin
declare @aluno_id int, @nota_maxima decimal(2,2), @nota_minima decimal(2,2), @nota_media decimal(2,2)

select @aluno_id = (select a.aluno_id from inserted a) 

select @nota_maxima = (select max(nota) from aluno_nota where aluno_id = @aluno_id)
select @nota_minima = (select min(nota) from aluno_nota where aluno_id = @aluno_id)
select @nota_media = ((select sum(nota) from aluno_nota where aluno_id = @aluno_id) / (select count(*) from aluno_nota where aluno_id = @aluno_id))

update aluno_auditoria set
	nota_mais_alta = @nota_maxima,
	nota_mais_baixa = @nota_minima,
	nota_media = @nota_media
where aluno_id = @aluno_id

end
go
-- VIEWS
CREATE VIEW Alunos_Aprovados AS
SELECT a.nome_completo, AVG(an.nota) AS media, m.nome AS materia_aprovada
FROM aluno a
JOIN aluno_nota an ON an.aluno_id = a.id
JOIN prova p ON p.id = an.prova_id
JOIN materia m ON m.id = p.materia_id
GROUP BY a.nome_completo, m.nome
HAVING AVG(an.nota) >= 6
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
go
