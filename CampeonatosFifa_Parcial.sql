CREATE TRIGGER FaseCampeonatos
ON Encuentro
FOR INSERT,UPDATE
AS BEGIN
	   SET NOCOUNT ON;
		IF EXISTS (
			SELECT 1
			FROM Inserted I
			JOIN Encuentro ON Encuentro.IdCampeonato = I.IdCampeonato AND 
			Encuentro.IdFase = I.IdFase
			AND (
			(Encuentro.IdPais1 = I.IdPais1 AND Encuentro.IdPais2 = I.IdPais2) OR 
			(Encuentro.IdPais1 = I.IdPais2 AND Encuentro.IdPais2 = I.IdPais1)
			)			
		)
		BEGIN 
			RAISERROR ('Ya existe un encuentro entre estos dos países en la misma fase y campeonato.', 16, 1);
			RETURN;
		END
	END;
GO



	