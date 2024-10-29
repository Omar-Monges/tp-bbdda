IF EXISTS (SELECT * FROM sys.databases WHERE name = 'G2900G19')
	USE G2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1)
GO
--USE master
--DROP DATABASE G2900G19
------------------------------------------------Esquema Empleado------------------------------------------------
--Calcula el cuil de un empleado mediante un DNI y el Sexo:
--	DROP FUNCTION Empleado.calcularCUIL		<--- ¡Primero borrar el procedure agregarEmpleado!
--	DROP PROCEDURE Empleado.agregarEmpleado
--	PRINT Empleado.calcularCUIL('42781944','M')
CREATE OR ALTER FUNCTION Empleado.calcularCUIL (@DNI VARCHAR(8), @Sexo CHAR(1))
RETURNS VARCHAR(13)
AS BEGIN
	DECLARE @Aux VARCHAR(10) = '5432765432',
			@DNIAux VARCHAR(10);
	DECLARE @DigInt TINYINT,
			@CursorIndice TINYINT = 1,
			@Resto TINYINT;
	DECLARE @Sumador SMALLINT=0;
	DECLARE @Prefijo VARCHAR(2);

	IF (@Sexo = 'F')
		SET @Prefijo = '27';
	ELSE
		SET @Prefijo = '20';
	SET @DNIAux = @Prefijo + @DNI;
	WHILE (@CursorIndice <= LEN(@DNIAux))
	BEGIN
		SET @DigInt = CAST(SUBSTRING(@DNIAux,@CursorIndice,1) AS TINYINT);
		SET @Sumador = @Sumador + (@DigInt * CAST(SUBSTRING(@Aux,@CursorIndice,1) AS TINYINT));
		SET @CursorIndice = @CursorIndice + 1;
	END;
	SET @Resto = @Sumador % 11;
	IF (@Resto = 0)
		RETURN @Prefijo+'-'+@DNI+'-0';
	IF(@Resto =1)
	BEGIN
		IF (@Sexo = 'M')
			RETURN '23-'+@DNI+'-9';
		RETURN '23-'+@DNI+'-4';
	END
	RETURN @Prefijo+'-'+@DNI+'-'+CAST((11-@Resto) AS CHAR);
END
GO
--Agregar un Empleado
--Drop Empleado.agregarEmpleado
CREATE OR ALTER PROCEDURE Empleado.agregarEmpleado (@DNI VARCHAR(8),@Nombre VARCHAR(50),@Apellido VARCHAR(50),@Sexo CHAR(1),
										@EmailPersonal VARCHAR(50),@EmailEmpresa VARCHAR(50),@IDSucursal INT,
										@IDTurno INT,@IDCargo INT,@Calle VARCHAR(255),@NumCalle SMALLINT,@CodPostal SMALLINT,
										@Localidad VARCHAR(255),@Piso TINYINT = NULL,@Departamento TINYINT)
AS BEGIN
	DECLARE @IDDireccion INT;

	IF (@DNI NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. El DNI es inválido.',16,1);
		RETURN;
	END;

	IF (@Nombre IS NULL OR LEN(LTRIM(RTRIM(@Nombre))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. El Nombre es inválido.',16,1);
		RETURN;
	END;

	IF (@Apellido IS NULL OR LEN(LTRIM(RTRIM(@Nombre))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. El Apellido es inválido.',16,1);
		RETURN;
	END;

	IF (@Sexo NOT IN ('M','F'))
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. El sexo es inválido.',16,1);
		RETURN;
	END

	IF (@EmailPersonal NOT LIKE '%@%.com')
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. El Email Personal es inválido.',16,1);
		RETURN;
	END;

	IF (@EmailEmpresa NOT LIKE '%@super.com')
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. El Email de la Empresa tiene un formato inválido.',16,1);
		RETURN;
	END;

	IF (@IDSucursal NOT IN (Select IDSucursal FROM Sucursal.Sucursal))
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. El ID de la sucursal no existe.',16,1);
		RETURN;
	END;

	IF (@IDTurno NOT IN (SELECT IDTurno FROM Sucursal.Turno))
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. El ID del turno no existe.',16,1);
		RETURN;
	END;

	IF (@IDCargo NOT IN (SELECT IDCargo FROM Sucursal.Cargo))
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. El ID del cargo no existe.',16,1);
		RETURN;
	END;
	
	IF ((@Piso IS NULL AND @Departamento IS NOT NULL) OR (@Piso IS NOT NULL OR @Departamento IS NULL))
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. La dirección es inválida.',16,1);
		RETURN;
	END;

	IF ((@Calle IS NULL OR LEN(LTRIM(RTRIM(@Calle))) = 0) OR (@NumCalle IS NULL OR @NumCalle<0)
		OR (@Localidad IS NULL OR LEN(LTRIM(RTRIM(@Localidad))) = 0) OR (@CodPostal IS NULL OR @CodPostal<0))
	BEGIN
		RAISERROR('Error en el procedimiento agregarEmpleado. La direccion es inválida.',16,1);
		RETURN;
	END;

	IF (@Piso IS NULL AND @Departamento IS NULL) --Si los dos son NULL es porque NO es un edificio
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Direccion.Direccion 
						WHERE Localidad <> @Localidad OR CodPostal <> @CodPostal OR Calle <> @Calle OR Numero <> @NumCalle)
		BEGIN--NO existe la direccion
				INSERT INTO Direccion.Direccion(Calle,Numero,CodPostal,Localidad,Piso,Departamento) VALUES
					(@Calle,@NumCalle,@CodPostal,@Localidad,@Piso,@Departamento);
		END
	END
	ELSE --Si entra en el else el domicilio es un edificio!
	BEGIN
		IF EXISTS (SELECT 1 FROM Direccion.Direccion 
				WHERE  Localidad LIKE @Localidad AND CodPostal = @CodPostal AND Calle = @Calle AND Numero LIKE @NumCalle)
	END

	SET @IDDireccion = (SELECT DISTINCT IDDireccion FROM Direccion.Direccion 
						WHERE Numero = @NumCalle AND Calle LIKE @Calle AND CodPostal = @CodPostal AND Localidad LIKE @Localidad);

	INSERT INTO Empleado.Empleado(DNI,Nombre,Apellido,IDDireccion,EmailPersonal,EmailEmpresa,IDSucursal,IDTurno,IDCargo,CUIL) 
	VALUES(@DNI,@Nombre,@Apellido,@IDDireccion,@EmailPersonal,@EmailEmpresa,@IDSucursal,@IDTurno,@IDCargo,Empleado.calcularCuil(@DNI,@Sexo));
END;
GO
---Modificar Empleado
--DROP PROCEDURE Empleado.modificarEmpleado
CREATE OR ALTER PROCEDURE Empleado.modificarEmpleado(@Legajo INT, @IDDireccion INT = NULL,@EmailPersonal VARCHAR(255)=NULL,
													@IDTurno INT=NULL,@IDCargo INT=NULL)
AS BEGIN
	UPDATE Empleado.Empleado
	SET IDDireccion = COALESCE(@IDDireccion,IDDireccion),
		EmailPersonal = COALESCE(@EmailPersonal,EmailPersonal),
		IDTurno = COALESCE(@IDTurno,IDTurno),
		IDCargo = COALESCE(@IDCargo,IDCargo)
	WHERE Legajo = @Legajo;
END
GO
--Eliminar Empleado
--DROP PROCEDURE Empleado.eliminarEmpleado
CREATE OR ALTER PROCEDURE Empleado.eliminarEmpleado(@Legajo INT)
AS BEGIN
	IF (@Legajo IS NULL)
		RETURN;

	ALTER TABLE Empleado.Empleado
		DROP CONSTRAINT PK_Empleado;
	ALTER TABLE Factura.Factura
		DROP CONSTRAINT FK_FacturaEmpleadoM;
	ALTER TABLE Direccion.Direccion
		DROP CONSTRAINT PK_Direccion;

	
		
	DELETE FROM Direccion.Direccion 
		WHERE Direccion.IDDireccion = (SELECT DISTINCT e.IDDireccion FROM Empleado.Empleado e WHERE Legajo = @Legajo);
	UPDATE Factura.Factura
		SET LegajoEmpleado = NULL
		WHERE LegajoEmpleado = @Legajo;
	DELETE FROM Empleado.Empleado
		WHERE Legajo = @Legajo;

	ALTER TABLE Empleado.Empleado
		ADD CONSTRAINT PK_Empleado PRIMARY KEY(Legajo); 
	ALTER TABLE Factura.Factura
		ADD CONSTRAINT FK_FacturaEmpleado FOREIGN KEY(LegajoEmpleado) REFERENCES Empleado.Empleado(Legajo);
	ALTER TABLE Direccion.Direccion
		ADD CONSTRAINT PK_Direccion PRIMARY KEY(IDDireccion);
END
GO
--Ver toda la tabla de empleados junto a su turno,cargo y sucursal en la que trabaja.
--DROP VIEW Empleado.verEmpleados
--SELECT * FROM Empleado.verDatosDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosDeEmpleados AS
	WITH EmpleadoCTE AS
	(
		SELECT Legajo,IDSucursal,IDCargo,IDTurno
			FROM Empleado.Empleado
	),CargoEmpleado (Legajo,IDSucursal,IDTurno,Cargo) AS
	(
		SELECT e.Legajo,e.IDSucursal,e.IDTurno,c.Descripcion 
			FROM Sucursal.Cargo c JOIN EmpleadoCTE e ON c.IDCargo = e.IDCargo
	),SucursalEmpleado (Legajo,IDTurno,Cargo,LocalidadSucursal) AS
	(
		SELECT Legajo,IDTurno,Cargo,d.Localidad
			FROM 
			(
				SELECT Legajo,IDTurno,s.IDDireccion,Cargo 
					FROM Sucursal.Sucursal s JOIN CargoEmpleado c ON s.IDSucursal = c.IDSucursal
			) AS T JOIN Direccion.Direccion d ON d.IDDireccion = T.IDDireccion
	),TurnoEmpleado (Legajo,Cargo,LocalidadSucursal,Turno) AS
	(
		SELECT Legajo,Cargo,LocalidadSucursal,t.Descripcion 
			FROM Sucursal.Turno t JOIN SucursalEmpleado e ON t.IDTurno = e.IDTurno
	),DatosEmpleado AS
	(
		SELECT Empl.*,t.Cargo,t.LocalidadSucursal,t.Turno
		FROM
		(
			SELECT e.Legajo,e.CUIL,e.Apellido,e.Nombre,e.EmailPersonal,e.EmailEmpresa,d.Calle,
					d.Numero,COALESCE(d.Piso,'-') AS Piso,COALESCE(d.Departamento,'-') AS Departamento,
					d.CodPostal,d.Localidad AS Ciudad
				FROM Empleado.Empleado e JOIN Direccion.Direccion d ON e.IDDireccion = e.IDDireccion
		) AS Empl JOIN TurnoEmpleado t ON Empl.Legajo = t.Legajo
	)
	SELECT * FROM DatosEmpleado;
GO
--Ver los datos personales de los empleados
--DROP VIEW Empleado.verDatosPersonalesDeEmpleados
--SELECT * FROM Empleado.verDatosPersonalesDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosPersonalesDeEmpleados AS
	SELECT e.Legajo,e.Apellido,e.Nombre,e.CUIL,e.EmailEmpresa,e.EmailPersonal,
			d.Calle,d.Numero,d.CodPostal,COALESCE(d.Piso,'-') AS Piso,COALESCE(d.Departamento,'-') AS Departamento
		FROM Empleado.Empleado  e JOIN Direccion.Direccion d ON e.IDDireccion = d.IDDireccion
GO
------------------------------------------------Producto------------------------------------------------
--Procedimiento almacenado para agregar una categoría de los productos
--SELECT name,collation_name from sys.databases
--DROP PROCEDURE Producto.AgregarTipoDeProducto;
CREATE OR ALTER PROCEDURE Producto.agregarTipoDeProducto (@Descripcion VARCHAR(255))
AS BEGIN
	IF EXISTS (SELECT 1 FROM Producto.TipoDeProducto 
				WHERE Descripcion LIKE @Descripcion COLLATE Modern_Spanish_CI_AI)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado "AgregarTipoDeProducto". La descripción ya se encuentra ingresada.',16,1);
		RETURN;
	END
	INSERT INTO Producto.TipoDeProducto(Descripcion) VALUES (@Descripcion);
END
GO
--Vista para ver los productos junto a su categoría
--DROP VIEW Producto.VerListadoDeProductos
--SELECT * FROM Producto.VerListadoDeProductos
CREATE OR ALTER VIEW Producto.verListadoDeProductos AS
	SELECT IDProducto,PrecioUnitario,PrecioReferencia,UnidadReferencia,t.Descripcion
		FROM Producto.Producto p JOIN Producto.TipoDeProducto t ON p.IDTipoDeProd = t.IDTipoDeProd;
GO
--28/10 19:27 -> Valor $968 y $1008 en https://dolarito.ar
--Devuelve el valor del dolar en pesos
--DROP PROCEDURE Producto.PasajeDolarAPesos
--DECLARE @dolar DECIMAL(6,2); EXEC Producto.pasajeDolarAPesos @dolar OUTPUT; PRINT @dolar
CREATE OR ALTER PROCEDURE Producto.pasajeDolarAPesos(@dolarPesificado DECIMAL(6,2) OUTPUT)
AS
BEGIN
	DECLARE @valorDolar DECIMAL(6,2);
	DECLARE @url NVARCHAR(336) = 'https://dolarapi.com/v1/dolares/oficial';

	DECLARE @Object INT;
	DECLARE @json TABLE(DATA NVARCHAR(MAX));
	DECLARE @respuesta NVARCHAR(MAX);

	SET NOCOUNT ON;
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	EXEC sp_configure 'Ole Automation Procedures', 1;
	RECONFIGURE;

	EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
	EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';
	EXEC sp_OAMethod @Object, 'SEND';
	EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT, @json OUTPUT;

	INSERT INTO @json 
		EXEC sp_OAGetProperty @Object, 'RESPONSETEXT';

	DECLARE @datos NVARCHAR(MAX) = (SELECT DATA FROM @json)
	SELECT @dolarPesificado=venta FROM OPENJSON(@datos)
	WITH
	(
			moneda VARCHAR(15) '$.moneda',
			casa VARCHAR(15) '$.casa',
			nombre VARCHAR(15) '$.nombre',
			compra DECIMAL(6, 2) '$.compra',
			venta DECIMAL(6, 2) '$.venta',
			fechaActualizacion DATETIME2 '$.fechaActualizacion'
	);
	EXEC sp_configure 'Ole Automation Procedures', 0;
	RECONFIGURE;
	EXEC sp_configure 'show advanced options', 0;
	RECONFIGURE;
	SET NOCOUNT OFF;
END
GO
--Importar Catalogo CSV 
--DROP PROCEDURE Producto.importarCatalogoCSV
/*
DECLARE @rutaArchivo VARCHAR(MAX);
SET @rutaArchivo = 'D:\unlam\BDDPlus\catalogo.csv'
EXEC Producto.ImportarCatalogoCSV @rutaArchivo
*/--
CREATE OR ALTER PROCEDURE Producto.importarCatalogoCSV (@rutaArchivo varchar(MAX))
AS BEGIN
	CREATE TABLE #Catalogo
	(
		Id VARCHAR(255),
		Categoria VARCHAR(255),
		Nombre VARCHAR(255),
		Precio VARCHAR(255),
		PrecioReferencia VARCHAR(255),
		UnidadReferencia VARCHAR(255),
		FechaHora VARCHAR(255)
	);

	CREATE TABLE #Catalogo2
	(
		Campo NVARCHAR(MAX)
	);
	DECLARE @SqlDinamico NVARCHAR(MAX); --Si es varchar(max) tira error
	DECLARE @valorDelDolar DECIMAL(6,2);

	BEGIN TRY
		SET @SqlDinamico = 'BULK INSERT #Catalogo2
						FROM '''+LTRIM(RTRIM(@rutaArchivo))+'''
						WITH
						(
							FIELDTERMINATOR = ''0x0A'',
							ROWTERMINATOR = ''0x0A'',
							CODEPAGE=''1200'',
							FIRSTROW = 2
						);';
		EXEC sp_executesql @SqlDinamico;
	END TRY
	BEGIN CATCH
		RAISERROR ('Procedimiento importarCatalogoCSV Fallido. Error en la ruta ingresada.',16,1);
		RETURN;
	END CATCH

	UPDATE #Catalogo2 SET Campo = REPLACE(CAMPO,N'単','ñ')
	SELECT * FROM #Catalogo2
	SELECT * FROM #Catalogo
	--SELECT *,LAST_VALUE(Nombre) OVER(ORDER BY Nombre) FROM #Catalogo 
	--SELECT DISTINCT Categoria FROM #Catalogo
	--EXEC Producto.PasajeDolarAPesos @valorDelDolar OUTPUT;

---TERMINAR
	DROP TABLE #Catalogo2
	DROP TABLE #Catalogo;
END
GO
------------------------------------------------Esquema Factura------------------------------------------------
--DROP VIEW Factura.verFactura
--SELECT * FROM Factura.verFactura
CREATE OR ALTER VIEW Factura.verFactura AS
	WITH FacturaFK AS
	(
		SELECT IDFactura,IDSucursal,IDMedioDePago
			FROM Factura.Factura
	),FacturaSucursal (IDFactura,IDMedioDePago,Sucursal) AS
	(
		SELECT IDFactura,IDMedioDePago,d.Localidad
			FROM 
			(
				SELECT IDFactura,IDMedioDepago,IDDireccion 
					FROM FacturaFK f JOIN Sucursal.Sucursal s ON f.IDSucursal = s.IDSucursal
			) AS T JOIN Direccion.Direccion d ON T.IDDireccion = d.IDDireccion
	),FacturaMedioDePago (IDFactura,[Medio De Pago],Sucursal) AS
	(
		SELECT IDFactura,m.Descripcion,Sucursal
			FROM FacturaSucursal s JOIN Factura.MedioDePago m ON s.IDMedioDePago = m.IDMedioDePago
	),FacturaDetalle AS
	(
		SELECT mp.IDFactura,IDDetalleFactura,[Medio De Pago],Sucursal,IDProducto,Cantidad
			FROM FacturaMedioDePago mp JOIN Factura.DetalleFactura d ON mp.IDFactura = d.IDFactura
	),FacturaResumen (IDFactura,IDDetalleFactura,NombreProd,[Medio De Pago],Sucursal,Cantidad,PrecioReferencia,UnidadReferencia) AS
	(
		SELECT IDFactura,IDDetalleFactura,p.Descripcion,[Medio De Pago],Sucursal,
				Cantidad,PrecioReferencia,UnidadReferencia
			FROM FacturaDetalle d JOIN Producto.Producto p ON d.IDProducto = p.IDProducto
	),FacturaPrecioTotal AS
	(
		SELECT r.IDFactura,r.IDDetalleFactura,f.TipoFactura,f.TipoCliente,
					r.NombreProd,r.PrecioReferencia,r.Cantidad,r.PrecioReferencia*r.Cantidad  AS Total,
					f.FechaHora,r.[Medio De Pago],f.LegajoEmpleado,r.Sucursal
			FROM FacturaResumen r  JOIN Factura.Factura f ON r.IDFactura = f.IDFactura
	)SELECT IDFactura,IDDetalleFactura,TipoFactura,TipoCliente,
			NombreProd,PrecioReferencia AS Precio,Cantidad,SUM(TOTAL) OVER (PARTITION BY IDFactura,IDDetalleFactura) AS TOTAL,
			FechaHora,[Medio De Pago],LegajoEmpleado AS Empleado,Sucursal
		FROM FacturaPrecioTotal
GO
------------------------------------------------Esquema Dirección------------------------------------------------

--DROP FUNCTION Direccion.cantidadDeHabitantesEnDireccion
--DECLARE num INT;PRINT Direccion.cantidadDeHabitantesEnDireccion (@num)
CREATE OR ALTER FUNCTION Direccion.cantidadDeHabitantesEnDireccion (@IDDireccion INT)
RETURNS INT
AS BEGIN
		SELECT * FROM sys.all_columns
	RETURN 1;
END
GO
------------------------------------------------Empleado------------------------------------------------
------------------------------------------------Empleado------------------------------------------------
CREATE TABLE TablaUno
(
	ID INT,
	CONSTRAINT PK_TablaUno PRIMARY KEY(ID)
)

CREATE TABLE TablaDos
(
	Cod INT,
	IDUno INT,
	CONSTRAINT PK_TablaDos PRIMARY KEY(Cod),
	CONSTRAINT FK_TablaDosUno FOREIGN KEY(IDUno) REFERENCES TablaUno(ID)
)
INSERT INTO TablaUno VALUES (9)
INSERT INTO TablaDos VALUES (1,9)

ALTER TABLE TablaDos
	DROP CONSTRAINT FK_TablaDosUno
ALTER TABLE TablaUno
	DROP CONSTRAINT PK_TablaUno

UPDATE TablaDos SET IDUno=NULL WHERE IDUno=9
DELETE FROM TablaUno WHERE ID=9;
ALTER TABLE TablaUno
	ADD CONSTRAINT PK_TablaUno PRIMARY KEY(ID)
ALTER TABLE TablaDos
	ADD CONSTRAINT FK_TablaDosUno Foreign KEY(IDUno) REFERENCES TABLAUNO(ID)

	SELECT * FROM TablaUno
	SELECT * FROM TablaDos

DROP TABLE TablaUno
DROP TABLE TablaDos