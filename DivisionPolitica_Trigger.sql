--- A
CREATE TRIGGER ActualizarCapitalRegion
ON Ciudad
FOR INSERT, UPDATE
AS
BEGIN
    -- Validar si se está insertando o actualizando una ciudad como capital de región
    IF EXISTS (SELECT * FROM Inserted WHERE CapitalRegion = 1)
    BEGIN
        -- Verificar si ya existe otra capital en la misma región
        IF EXISTS (
            SELECT 1
            FROM Inserted I
            JOIN Ciudad C ON I.IdRegion = C.IdRegion
            WHERE I.CapitalRegion = 1 AND C.CapitalRegion = 1 AND C.Id <> I.Id
        )
        BEGIN
            RAISERROR('No se acepta más de una capital por región', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END

        -- Asegurarse de que las demás ciudades en la región no sean capital
        UPDATE Ciudad
        SET CapitalRegion = 0
        FROM Ciudad C
        JOIN Inserted I ON C.IdRegion = I.IdRegion AND C.Id <> I.Id
        WHERE I.CapitalRegion = 1
    END
END
GO
--- B
CREATE TRIGGER ActualizarCapitalPais
ON Ciudad
FOR INSERT, UPDATE
AS
BEGIN
    -- Evitar ejecución recursiva del trigger
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    -- Asegurarnos de que solo quede una ciudad como CapitalPais = 1 por cada Pais 
    WITH UltimaCapital AS (
        SELECT C.Id, R.IdPais
        FROM Inserted I
		JOIN Ciudad C ON C.Id=I.Id
        JOIN Region R ON C.IdRegion=R.Id
        WHERE I.CapitalPais = 1
  )

    -- Actualizar todas las ciudades del mismo país, dejando solo una como CapitalPais = 1
    UPDATE C
    SET C.CapitalPais = CASE 
        WHEN C.Id = U.Id THEN 1
        ELSE 0
    END
    FROM Ciudad C
    JOIN Region R ON C.IdRegion = R.Id
    JOIN UltimaCapital U ON U.IdPais = R.IdPais
END;
GO


