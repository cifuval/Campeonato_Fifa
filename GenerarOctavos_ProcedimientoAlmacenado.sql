CREATE OR ALTER PROCEDURE GenerarOctavos
	@IdGrupoA INT,
	@IdGrupoB INT,
	@IdEstadio INT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @IdCampeonato INT ; 
	
	-- Obtener el campeonato asociado al grupo 
    SELECT @IdCampeonato = IdCampeonato 
  FROM Grupo 
  WHERE Id = @IdGrupoA;
 
    DECLARE @IdFaseGrupos INT = 1; -- Fase de grupos
    DECLARE @IdFaseOctavos INT = 2; -- Octavos de final

WITH Resultados AS (
	SELECT 
	GrupoPais.IdGrupo,
	Encuentro.IdCampeonato,
	Encuentro.IdPais1 AS IdPais,
	SUM(
		CASE 
			WHEN Encuentro.Goles1 > Encuentro.Goles2 THEN 3
			WHEN Encuentro.Goles2 = Encuentro.Goles2 THEN 1
			ELSE 0
		END
	) AS Puntos,
	SUM (Encuentro.Goles1 - Encuentro.Goles2) AS DiferenciaGoles
	FROM Encuentro
	INNER JOIN GrupoPais ON GrupoPais.IdPais = Encuentro.IdPais1
	WHERE Encuentro.IdFase = @IdFaseGrupos AND Encuentro.IdCampeonato = @IdCampeonato
	GROUP BY GrupoPais.IdGrupo,Encuentro.IdCampeonato,Encuentro.IdPais1
	
	UNION ALL
	
	Select
	GrupoPais.IdGrupo,
	Encuentro.IdCampeonato,
	Encuentro.IdPais2 AS IdPais,
	SUM(
		CASE 
			WHEN Encuentro.Goles2 > Encuentro.Goles1 THEN 3
			WHEN Encuentro.Goles2 = Encuentro.Goles2 THEN 1
			ELSE 0
		END
	) AS Puntos,
	SUM (Encuentro.Goles2 - Encuentro.Goles1) AS DiferenciaGoles
	FROM Encuentro
	INNER JOIN GrupoPais ON GrupoPais.IdPais = Encuentro.IdPais2
	WHERE Encuentro.IdFase = @IdFaseGrupos AND Encuentro.IdCampeonato = @IdCampeonato
	GROUP BY GrupoPais.IdGrupo,Encuentro.IdCampeonato,Encuentro.IdPais2
),

	TablaPosiciones AS (
        SELECT 
            IdGrupo,
            IdCampeonato,
            IdPais,
            SUM(Puntos) AS TotalPuntos,
            SUM(DiferenciaGoles) AS TotalDiferenciaGoles,
            ROW_NUMBER() OVER(
                PARTITION BY IdGrupo
                ORDER BY SUM(Puntos) DESC, SUM(DiferenciaGoles) DESC
            ) AS Posicion
        FROM Resultados
        GROUP BY IdGrupo, IdCampeonato, IdPais
    )



	INSERT INTO Encuentro (IdPais1,IdPais2,IdFase,IdCampeonato,IdEstadio)
	SELECT 
		GA1.IdPais, 
		GB2.IdPais,
		@IdFaseOctavos,
		@IdCampeonato,
		@IdEstadio
	FROM TablaPosiciones GA1
	CROSS JOIN TablaPosiciones GB2
	WHERE  GA1.IdGrupo = @IdGrupoA AND GA1.Posicion = 1
	AND GB2.IdGrupo = @IdGrupoB AND GB2.Posicion = 2
	
	UNION ALL
	
	SELECT 
		GA2.IdPais,
		GB1.IdPais ,
		@IdFaseOctavos,
		@IdCampeonato,
		@IdEstadio
	FROM TablaPosiciones GA2
	CROSS JOIN TablaPosiciones GB1
	WHERE GA2.IdGrupo = @IdGrupoA AND GA2.Posicion = 2
	AND GB1.IdGrupo = @IdGrupoB AND GB1.Posicion = 1;
	
	PRINT 'Encuentros de octavos generados correctamente.';
END;
GO


