/*Lista Codigo de errores:
	 1 -> agregarEmpleado
	 2 -> agregarSucursal
	 3 -> agregarCargo
	 4 -> agregarTurno
	 5 -> agregarProducto
	 6 -> agregarTipoDeProducto
	 7 -> modificarSucursal
	 8 -> agregarFactura
	 9 -> modificarEmpleado
	10 -> modificarSucursal
	11 -> modificarCargo
	12 -> modificarProducto
	13 -> modificarTurno
	14 -> agregarFactura
	15 -> exportarResumenTrimestral
	16 -> exportarResumenRangoFechas
*/
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script est� dise�ado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO
--  USE master
--DROP DATABASE Com2900G19
------------------------------------------------Esquema Direcci�n------------------------------------------------
--Ver los domicilios de todos los empleados.
--DROP VIEW Direccion.verDomiciliosDeEmpleados
--		SELECT * FROM Direccion.verDomiciliosDeEmpleados
CREATE OR ALTER VIEW Direccion.verDomiciliosDeEmpleados AS
	SELECT e.legajo,d.calle,d.numeroDeCalle,d.piso,d.departamento,d.codigoPostal,d.localidad,d.provincia FROM Empleado.Empleado e JOIN Direccion.Direccion d ON e.idDireccion = d.idDireccion;
GO
--Ver las direcciones de todas las sucursales
--DROP VIEW Direccion.verDireccionesDeSucursales
--		SELECT *  FROM Direccion.verDireccionesDeSucursales
CREATE OR ALTER VIEW Direccion.verDireccionesDeSucursales AS
	SELECT s.idSucursal,d.calle,d.numeroDeCalle,d.codigoPostal,d.localidad,d.provincia
		FROM Sucursal.Sucursal s JOIN Direccion.Direccion d ON d.idDireccion = s.idDireccion;
GO
--Obtener un codigo Postal mediante una API
--		https://api.zippopotam.us/ar/buenos%20aires/laferrere
--		https://www.geonames.org/postalcode-search.html?q=san+isidro&country=AR
--		DROP CREATE OR ALTER PROCEDURE Direccion.obtenerCodigoPostal
--		DECLARE @codPostal VARCHAR(10);EXEC Direccion.obtenerCodigoPostal 'Laferrere',@codPostal OUTPUT; print @codPostal
CREATE OR ALTER PROCEDURE Direccion.obtenerCodigoPostal (@ciudad VARCHAR(50),@codigoPostal varchar(10) OUTPUT)
AS BEGIN
	SET @ciudad = REPLACE(@ciudad,' ','%20');
	
	SET @ciudad = REPLACE(@ciudad,'�','a');
	SET @ciudad = REPLACE(@ciudad,'�','e');
	SET @ciudad = REPLACE(@ciudad,'�','i');
	SET @ciudad = REPLACE(@ciudad,'�','o');
	SET @ciudad = REPLACE(@ciudad,'�','u');
	
	DECLARE @url NVARCHAR(336) = 'https://api.zippopotam.us/ar/buenos%20aires/'+ @ciudad;

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
	SELECT @codigoPostal = codPostal FROM OPENJSON(@datos)
	WITH
	(
			lugares NVARCHAR(MAX) '$.places' AS JSON)
			cross apply openjson(lugares) with (
			codPostal Nvarchar(MAX) '$."post code"')

	EXEC sp_configure 'Ole Automation Procedures', 0;
	RECONFIGURE;
	EXEC sp_configure 'show advanced options', 0;
	RECONFIGURE;
	SET NOCOUNT OFF;
END
GO
------------------------------------------------Esquema Empleado------------------------------------------------
--Calcula el cuil de un empleado mediante un DNI y el Sexo:
--	DROP FUNCTION Empleado.calcularCUIL		<--- �Primero borrar el procedure agregarEmpleado!
--	DROP PROCEDURE Empleado.agregarEmpleado
--	PRINT Empleado.calcularCUIL('42781944','M')		<--- Salida esperada: 20-42781944-3
CREATE OR ALTER FUNCTION Empleado.calcularCUIL (@dni CHAR(8), @sexo CHAR)
RETURNS CHAR(13)
AS BEGIN
	DECLARE @aux VARCHAR(10) = '5432765432',
			@dniAux VARCHAR(10);
	DECLARE @digInt TINYINT,
			@cursorIndice TINYINT = 1,
			@resto TINYINT;
	DECLARE @sumador SMALLINT = 0;
	DECLARE @prefijo VARCHAR(2);

	IF (@sexo = 'F')
		SET @prefijo = '27';
	ELSE
		SET @prefijo = '20';
	SET @dniAux = @prefijo + @DNI;
	WHILE (@cursorIndice <= LEN(@dniAux))
	BEGIN
		SET @digInt = CAST(SUBSTRING(@dniAux,@cursorIndice,1) AS TINYINT);
		SET @sumador = @sumador + (@digInt * CAST(SUBSTRING(@aux,@cursorIndice,1) AS TINYINT));
		SET @cursorIndice = @cursorIndice + 1;
	END;
	SET @resto = @sumador % 11;
	IF (@resto = 0)
		RETURN @prefijo + '-' + @dni+'-0';
	IF(@resto = 1)
	BEGIN
		IF (@sexo = 'M')
			RETURN '23-' + @dni + '-9';
		RETURN '23-' + @dni + '-4';
	END
	RETURN @prefijo + '-' + @dni + '-' + CAST((11-@resto) AS CHAR);
END
GO
--Agregar un Empleado
--Drop Empleado.agregarEmpleado
CREATE OR ALTER PROCEDURE Empleado.agregarEmpleado (@dni VARCHAR(8), @nombre VARCHAR(50), @apellido VARCHAR(50),
													@sexo CHAR, @emailPersonal VARCHAR(100)=NULL, @emailEmpresa VARCHAR(100),
													@idSucursal INT, @idTurno INT,@idCargo INT, @calle VARCHAR(255),
													@numCalle SMALLINT, @codPostal VARCHAR(255), @localidad VARCHAR(255),
													@provincia VARCHAR(255), @piso TINYINT = NULL, @numDepto TINYINT = NULL)
AS BEGIN
	DECLARE @idDireccion INT;
	DECLARE @cuil CHAR(13);

	IF (@dni IS NULL OR @dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del DNI es inv�lido.',16,1);
		RETURN;
	END;
	IF (@nombre IS NULL OR LEN(LTRIM(@nombre)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del Nombre es inv�lido.',16,1);
		RETURN;
	END;

	IF (@apellido IS NULL OR LEN(LTRIM(@apellido)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del Apellido es inv�lido.',16,1);
		RETURN;
	END;

	IF (@sexo IS NULL OR @sexo NOT IN ('F','M'))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado.El sexo del empleado es inv�lido.',16,1);
		RETURN;
	END;

	IF (@emailPersonal IS NULL OR @emailPersonal NOT LIKE '%@%.com')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El email personal es inv�lido.',16,1);
		RETURN;
	END;

	IF(@emailEmpresa IS NULL OR @emailEmpresa NOT LIKE '%@superA.com')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El email empresarial es inv�lido.',16,1);
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El id de la sucursal no existe.',16,1);
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM Sucursal.Turno WHERE idTurno = @idTurno)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El id del turno no existe.',16,1);
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM Sucursal.Cargo WHERE idCargo = @idCargo)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El id del cargo no existe.',16,1);
		RETURN;
	END;

	IF (@calle IS NULL OR (LEN(LTRIM(@calle)) = 0 OR @numCalle IS NULL OR @numCalle < 0 OR 
		@localidad IS NULL OR LEN(LTRIM(@localidad)) = 0 OR 
		LEN(LTRIM(@codPostal)) = 0 OR @provincia IS NULL OR LEN(LTRIM(@provincia)) = 0))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato de la direccion es inv�lida.',16,1);
		RETURN;
	END;

	IF ((@piso IS NOT NULL AND @numDepto IS NULL) OR (@piso IS NULL AND @numDepto IS NOT NULL))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del piso y departamento es inv�lido.',16,1);
		RETURN;
	END;

	INSERT INTO Direccion.Direccion(calle,numeroDeCalle,codigoPostal,piso,departamento,localidad,provincia) 
				VALUES(@calle,@numCalle,COALESCE(@codPostal,'-'),@piso,@numDepto,@localidad,@provincia);
	SET @idDireccion = SCOPE_IDENTITY();

	SET @emailPersonal = REPLACE(@emailPersonal,' ','');
	SET @emailEmpresa = REPLACE(@emailEmpresa,' ','');
	SET @cuil = Empleado.calcularCUIL(@dni,@sexo);

	INSERT INTO Empleado.Empleado(dni,nombre,apellido,idDireccion,emailPersonal,emailEmpresarial,idSucursal,idTurno,idCargo,cuil) 
				VALUES(@dni,@nombre,@apellido,@idDireccion,@emailPersonal,@emailEmpresa,@idSucursal,@idTurno,@idCargo,@cuil);
END;
GO
---Modificar Empleado
--DROP PROCEDURE Empleado.modificarEmpleado
CREATE OR ALTER PROCEDURE Empleado.modificarEmpleado(@legajo INT, @nombre VARCHAR(255), @apellido VARCHAR(255) = NULL,
													@emailPersonal VARCHAR(255)=NULL, @emailEmpresarial VARCHAR(255)=NULL,
													@idSucursal INT = NULL, @idTurno INT=NULL, @idCargo INT=NULL,
													@calle VARCHAR(255) = NULL, @numCalle SMALLINT = NULL, @codPostal SMALLINT = NULL, 
													@localidad VARCHAR(255) = NULL, @provincia VARCHAR(255) = NULL,
													@piso TINYINT = NULL, @numDepto TINYINT = NULL)
AS BEGIN
	DECLARE @viejoIDDireccion INT;

	IF NOT EXISTS (SELECT 9 FROM Empleado.Empleado WHERE legajo = @legajo)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. El legajo no existe.',16,9);
		RETURN
	END
		
	IF (LEN(LTRIM(@nombre)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. El nombre es inv�lido.',16,9);
		RETURN
	END

	IF (LEN(LTRIM(@apellido)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. El apellido es inv�lido.',16,9);
		RETURN
	END
	IF (@emailPersonal IS NOT NULL AND @emailPersonal NOT LIKE '%@%.com')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. El email personal es inv�lido.',16,9);
		RETURN
	END
	IF (@emailEmpresarial IS NOT NULL AND @emailEmpresarial NOT LIKE '%@superA.com')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. El email empresarial es inv�lido.',16,9);
		RETURN
	END
	IF @idSucursal IS NOT NULL AND NOT EXISTS (SELECT 9 FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. El ID del sucursal no existe.',16,9);
		RETURN
	END
	IF @idTurno IS NOT NULL AND NOT EXISTS (SELECT 9 FROM Sucursal.Turno WHERE idTurno = @idTurno)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. El ID del turno no existe.',16,9);
		RETURN
	END
	IF @idCargo IS NOT NULL AND NOT EXISTS (SELECT 9 FROM Sucursal.Cargo WHERE idCargo = @idCargo)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. EL ID del cargo no existe.',16,9);
		RETURN
	END
	IF (LEN(LTRIM(@calle)) = 0 OR LEN(LTRIM(@localidad)) = 0 OR LEN(LTRIM(@provincia)) = 0 OR LEN(LTRIM(@codPostal)) = 0 OR
		@numCalle < 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. La direcci�n es inv�lida.',16,9);
		RETURN;
	END
	IF ((@piso IS NOT NULL AND @numDepto IS NULL) OR (@piso IS NULL AND @numDepto IS NOT NULL))
	BEGIN
		RAISERROR ('ERror en el procedimiento almacenado modificarEmpleado. La direcci�n es inv�lida.',16,9);
		RETURN;
	END

	SET @viejoIDDireccion = (SELECT idDireccion FROM Empleado.Empleado WHERE legajo = @legajo);

	UPDATE Direccion.Direccion
		SET calle = COALESCE(@calle,calle),
			numeroDeCalle = COALESCE(@numCalle,numeroDeCalle),
			localidad = COALESCE(@localidad,localidad),
			codigoPostal = COALESCE(@codPostal,codigoPostal),
			piso = COALESCE(piso,@piso),
			departamento = COALESCE(@numDepto,departamento),
			provincia = COALESCE(@provincia,provincia)
		WHERE idDireccion = @viejoIDDireccion;

	UPDATE Empleado.Empleado
		SET nombre = COALESCE(@nombre,nombre),
			apellido = COALESCE(@apellido,apellido),
			emailPersonal = COALESCE(@emailPersonal,emailPersonal),
			emailEmpresarial = COALESCE(@emailEmpresarial,emailEmpresarial),
			idTurno = COALESCE(@idTurno,idTurno),
			idCargo = COALESCE(@idCargo,idCargo),
			idDireccion = COALESCE(@viejoIDDireccion,idDireccion)
		WHERE legajo = @legajo;
END
GO
--Eliminar Empleado
--DROP PROCEDURE Empleado.eliminarEmpleado
CREATE OR ALTER PROCEDURE Empleado.eliminarEmpleado(@legajo INT)
AS BEGIN
	DECLARE @idDireccion INT;

	SET @idDireccion = (SELECT idDireccion FROM Empleado.Empleado WHERE legajo = @legajo)
		
	UPDATE Factura.Factura
		SET legajo = NULL
		WHERE legajo = @legajo

	DELETE FROM Empleado.Empleado
		WHERE legajo = @legajo;

	DELETE FROM Direccion.Direccion
		WHERE idDireccion = @idDireccion;
END
GO
--Ver toda la tabla de empleados junto a su turno,cargo y sucursal en la que trabaja.
--DROP VIEW Empleado.verEmpleados
--		SELECT * FROM Empleado.verDatosDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosDeEmpleados AS
	WITH EmpleadoCTE AS
	(
		SELECT legajo,idTurno,idCargo,idSucursal,idDireccion 
			FROM Empleado.Empleado
	),CargoCTE (legajo,idDireccion,idSucursal,idTurno,cargo) AS
	(
		SELECT e.legajo,e.idDireccion,e.idSucursal,e.idTurno,c.nombreCargo 
			FROM EmpleadoCTE e JOIN Sucursal.Cargo c ON e.idCargo = c.idCargo
	),TurnoCTE (legajo,idDireccion,idSucursal,turno,cargo) AS
	(
		SELECT c.legajo,c.idDireccion,c.idSucursal,c.cargo,t.nombreTurno 
			FROM CargoCTE c JOIN Sucursal.Turno t ON c.idTurno = t.idTurno
	),SucursalCTE (legajo,cargo,turno,idDireccion,sucursal) AS
	(
		SELECT t.legajo,t.cargo,t.turno,t.idDireccion,sucursalDireccion.localidad
			FROM TurnoCTE t JOIN (SELECT s.idSucursal,d.localidad 
									FROM Sucursal.Sucursal s JOIN Direccion.Direccion d
										ON s.idDireccion = d.idDireccion
									) AS sucursalDireccion
				ON t.idSucursal = sucursalDireccion.idSucursal
	),DomicilioCTE AS
	(
		SELECT s.legajo,s.cargo,s.turno,s.sucursal,d.calle,d.numeroDeCalle,d.codigoPostal,
				d.piso,d.departamento,d.localidad,d.provincia
			FROM SucursalCTE s JOIN Direccion.Direccion d 
				ON s.idDireccion = d.idDireccion
	)
	SELECT e.legajo,e.cuil,e.apellido,e.nombre,e.emailEmpresarial,d.calle,d.numeroDeCalle,
			d.piso,d.departamento,d.localidad,d.turno,d.cargo,d.sucursal
		FROM DomicilioCTE d JOIN Empleado.Empleado e 
			ON d.legajo = e.legajo
GO
--Ver los datos personales de los empleados
--DROP VIEW Empleado.verDatosPersonalesDeEmpleados
--		SELECT * FROM Empleado.verDatosPersonalesDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosPersonalesDeEmpleados AS
	SELECT e.legajo,e.apellido,e.nombre,e.cuil,e.emailEmpresarial,e.emailPersonal,
			d.calle,d.numeroDeCalle,d.piso,d.departamento,d.codigoPostal,d.localidad
		FROM Empleado.Empleado  e JOIN Direccion.Direccion d ON e.idDireccion = d.idDireccion
GO
------------------------------------------------Esquema Sucursal------------------------------------------------
--Tabla Sucursal
--	Procedimiento almacenado que permite agregar una sucursal.
--	DROP PROCEDURE Sucursal.agregarSucursal
CREATE OR ALTER PROCEDURE Sucursal.agregarSucursal (@telefono VARCHAR(9),@horario VARCHAR(255),
													@calle VARCHAR(255),@numeroDeCalle SMALLINT,@codPostal VARCHAR(255),
													@localidad VARCHAR(255),@provincia VARCHAR(255))
AS BEGIN
	DECLARE @idDireccion INT;

	IF(@telefono IS NULL OR @telefono NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El telefono es inv�lido.',16,2);
		RETURN;
	END

	IF(@horario IS NULL OR LEN(LTRIM(@horario)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El horario es inv�lido.',16,2);
		RETURN;
	END

	IF(@calle IS NULL OR LEN(LTRIM(@calle)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La calle es inv�lida.',16,2);
		RETURN;
	END

	IF(@numeroDeCalle IS NULL OR @numeroDeCalle < 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El numero de la calle es inv�lido.',16,2);
		RETURN;
	END

	IF(LEN(LTRIM(@codPostal)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El c�digo postal es inv�lido.',16,2);
		RETURN;
	END

	IF(@localidad IS NULL OR LEN(LTRIM(@localidad)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La localidad es inv�lida.',16,2);
		RETURN;
	END

	IF(@provincia IS NULL OR LEN(LTRIM(@provincia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La provincia es inv�lida.',16,2);
		RETURN;
	END

	IF (@codPostal IS NULL)
		EXEC Direccion.obtenerCodigoPostal @localidad, @codPostal OUTPUT;

	INSERT INTO Direccion.Direccion (calle,numeroDeCalle,codigoPostal,localidad,provincia) 
			VALUES (@calle,@numeroDeCalle,COALESCE(@codPostal,'-'),@localidad,@provincia);
	SET @idDireccion = SCOPE_IDENTITY();
	INSERT INTO Sucursal.Sucursal (telefono,horario,idDireccion)
			VALUES (@telefono,@horario,@idDireccion);
END
GO
--	Procedimiento almacenado que permite modificar una sucursal.
--	DROP PROCEDURE Sucursal.modificarSucursal
CREATE OR ALTER PROCEDURE Sucursal.modificarSucursal (@idSucursal INT,@telefono VARCHAR(9) = NULL,
													@horario VARCHAR(255) = NULL,@calle VARCHAR(255) = NULL,
													@numeroDeCalle SMALLINT = NULL,@codPostal VARCHAR(255) = NULL,
													@localidad VARCHAR(255) = NULL,@provincia VARCHAR(255) = NULL)
AS BEGIN
	DECLARE @idDireccionSucursal INT = NULL;

	IF NOT EXISTS (SELECT 10 FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. El ID de la sucursal no existe.',16,10);
		RETURN;
	END

	IF(@telefono IS NOT NULL AND @telefono NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. El telefono.',16,10);
		RETURN;
	END

	IF(LEN(LTRIM(@horario)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. El horario es inv�lido.',16,10);
		RETURN;
	END

	IF(LEN(LTRIM(@calle)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. La calle es inv�lida.',16,10);
		RETURN;
	END

	IF(@numeroDeCalle < 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. El n�mero de la calle es inv�lido.',16,10);
		RETURN;
	END

	IF(LEN(LTRIM(@codPostal)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. El c�digo postal es inv�lido.',16,10);
		RETURN;
	END

	IF(LEN(LTRIM(@localidad)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. La localidad es inv�lida.',16,10);
		RETURN;
	END

	IF(LEN(LTRIM(@provincia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. La provincia es inv�lida.',16,10);
		RETURN;
	END

	SET @idDireccionSucursal = (SELECT idDireccion FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal);

	UPDATE Direccion.Direccion
		SET calle = COALESCE(@calle,calle),
			numeroDeCalle = COALESCE(@numeroDeCalle,numeroDeCalle),
			codigoPostal = COALESCE(@codPostal,codigoPostal),
			localidad = COALESCE(@localidad,localidad),
			provincia = COALESCE(@provincia,provincia)
		WHERE idDireccion = @idDireccionSucursal;

	UPDATE Sucursal.Sucursal
		SET telefono = COALESCE(@telefono,telefono),
			horario = COALESCE(@horario,horario)
		WHERE idSucursal = @idSucursal;

END;
GO
--	Procedimiento almacenado que permite eliminar una sucursal.
--	DROP PROCEDURE Sucursal.eliminarSucursal
CREATE OR ALTER PROCEDURE Sucursal.eliminarSucursal (@idSucursal INT)
AS BEGIN
	DECLARE @idDireccion INT;
	--Buscamos idDireccion para eliminar la direcci�n de la sucursal
	SET @idDireccion = (SELECT idDireccion FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal);
	
	UPDATE Empleado.Empleado
		SET idSucursal = NULL
		WHERE idSucursal = @idSucursal;

	UPDATE Factura.Factura
		SET idSucursal = NULL
		WHERE idSucursal = @idSucursal;

	DELETE FROM Sucursal.Sucursal
		WHERE idSucursal = @idSucursal;

	DELETE FROM Direccion.Direccion
		WHERE idDireccion = @idDireccion	
END
GO
--	Vista que permite ver la informaci�n de cada sucursal.
--	DROP VIEW Sucursal.verDatosDeSucursales
--	SELECT * FROM Sucursal.verDatosDeSucursales
CREATE OR ALTER VIEW Sucursal.verDatosDeSucursales AS
	SELECT s.idSucursal,s.horario,s.telefono,d.calle,d.numeroDeCalle,d.codigoPostal,d.localidad,d.provincia 
		FROM Sucursal.Sucursal s JOIN Direccion.Direccion d
		ON s.idDireccion = d.idDireccion;
GO 
--	Vista que permite ver a los empleados de cada sucursal
--	DROP VIEW Sucursal.verEmpleadosDeCadaSucursal
--	SELECT * FROM Sucursal.verEmpleadosDeCadaSucursal
CREATE OR ALTER VIEW Sucursal.verEmpleadosDeCadaSucursal AS
	SELECT s.idSucursal,e.legajo,e.cuil,e.apellido,e.nombre 
		FROM Sucursal.Sucursal s JOIN Empleado.Empleado e
		ON s.idSucursal = e.idSucursal;
GO
--Tabla Cargo
--	Procedimiento almacenado que permite agregar un cargo
--	DROP PROCEDURE Sucursal.agregarCargo
CREATE OR ALTER PROCEDURE Sucursal.agregarCargo (@nombreCargo VARCHAR(255))
AS BEGIN
	IF EXISTS (SELECT 1 FROM Sucursal.Cargo 
						WHERE nombreCargo = @nombreCargo)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarCargo. el cargo ya se encuentra ingresado',16,3);
		RETURN;
	END

	IF(@nombreCargo IS NULL OR LEN(LTRIM(RTRIM(@nombreCargo))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarCargo. El nombre del cargo es inv�lido.',16,3);
		RETURN;
	END

	INSERT Sucursal.Cargo (nombreCargo) VALUES (@nombreCargo);
END
GO
--	Procedimiento almacenado que permite modificar un cargo
--	DROP PROCEDURE Sucursal.modificarCargo
CREATE OR ALTER PROCEDURE Sucursal.modificarCargo (@idCargo INT,@nombreCargo VARCHAR(255))
AS BEGIN
	IF (@nombreCargo IS NULL OR LEN(LTRIM(RTRIM(@nombreCargo))) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarCargo.',16,11);
		RETURN;
	END
	UPDATE Sucursal.Cargo
		SET nombreCargo = COALESCE(@nombreCargo,nombreCargo)
		WHERE idCargo = @idCargo;
END
GO
--	Procedimiento almacenado que permite eliminar un cargo
--	DROP PROCEDURE Sucursal.eliminarCargo
CREATE OR ALTER PROCEDURE Sucursal.eliminarCargo (@idCargo INT)
AS BEGIN
	UPDATE Empleado.Empleado
		SET idCargo = NULL
		WHERE idCargo = @idCargo;

	DELETE FROM Sucursal.Cargo
		WHERE idCargo = @idCargo;
END
GO
--	Vista que permite ver el cargo que tiene cada empleado
--	DROP VIEW Sucursal.verCargoDeEmpleados
--	SELECT * FROM Sucursal.verCargoDeEmpleados
CREATE OR ALTER VIEW Sucursal.verCargoDeEmpleados AS
	SELECT e.legajo,e.cuil,e.apellido,e.nombre,c.nombreCargo 
		FROM Empleado.Empleado e JOIN Sucursal.Cargo c
		ON e.idCargo = c.idCargo;
GO
--Tabla Turno
--	Procedimiento almacenado que permite agregar un turno
--	DROP PROCEDURE Sucursal.agregarTurno
CREATE OR ALTER PROCEDURE Sucursal.agregarTurno (@nombreTurno VARCHAR(255))
AS BEGIN
	IF EXISTS (SELECT 1 FROM Sucursal.Turno 
					WHERE nombreTurno = @nombreTurno)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarTurno. El turno ya se encuentra ingresado',16,4);
		RETURN;
	END

	IF (@nombreTurno IS NULL OR LEN(LTRIM(RTRIM(@nombreTurno))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarTurno. El turno no es v�lido.',16,4);
		RETURN;
	END

	INSERT INTO Sucursal.Turno (nombreTurno) VALUES (@nombreTurno);
END
GO
--	Procedimiento almacenado que permite modificar un turno
--	DROP PROCEDURE Sucursal.modificarTurno
CREATE OR ALTER PROCEDURE Sucursal.modificarTurno (@idTurno INT, @nombreTurno VARCHAR(255))
AS BEGIN
	IF (@nombreTurno IS NULL OR LEN(LTRIM(@nombreTurno)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiemto almacenado modificarTurno.',16,13);
		RETURN;
	END

	UPDATE Sucursal.Turno
		SET nombreTurno = @nombreTurno
		WHERE idTurno = @idTurno;
END
GO
--	Procedimiento almacenado qeu permite eliminar un turno
--	DROP PROCEDURE Sucursal.eliminarTurno
CREATE OR ALTER PROCEDURE Sucursal.eliminarTurno (@idTurno INT)
AS BEGIN
	UPDATE Empleado.Empleado
		SET idTurno = NULL
		WHERE idTurno = @idTurno

	DELETE FROM Sucursal.Turno 
		WHERE idTurno = @idTurno;
END
GO
--	Vista que permite ver los turnos que tiene cada empleado.
--	DROP VIEW Sucursal.verTurnosDeEmpleados
--	SELECT * FROM Sucursal.verTurnosDeEmpleados
CREATE OR ALTER VIEW Sucursal.verTurnosDeEmpleados AS
	SELECT e.legajo,e.cuil,e.apellido,e.nombre,t.nombreTurno 
			FROM Empleado.Empleado e JOIN Sucursal.Turno t
			ON e.idTurno = t.idTurno;
GO
------------------------------------------------Producto------------------------------------------------
--Tabla Producto
--Procedimiento almacenado que permite agregar un producto
--DROP PROCEDURE Sucursal.
CREATE OR ALTER PROCEDURE Producto.agregarProducto (@idTipoDeProducto INT,@descripcionProducto VARCHAR(255),
													@precioUnitario DECIMAL(10,2),@precioReferencia DECIMAL(10,2) = NULL,
													@unidadReferencia VARCHAR(255) = NULL)
AS BEGIN
	IF EXISTS (SELECT 5 FROM Producto.Producto WHERE descripcionProducto = @descripcionProducto)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. El producto ya existe.',16,5);
		RETURN;
	END

	IF (LEN(LTRIM(@descripcionProducto)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. La descripci�n del producto es incorrecta',16,5);
		RETURN;
	END

	IF(LEN(LTRIM(@unidadReferencia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. El precio o unidad de referencia son incorrectos.',16,5);
		RETURN;
	END

	IF(@precioReferencia IS NULL AND @unidadReferencia IS NULL)
	BEGIN
		SET @precioReferencia = @precioUnitario;
		SET @unidadReferencia = 'unidad';
	END

	BEGIN TRY
		INSERT INTO Producto.Producto (idTipoDeProducto,descripcionProducto,precioUnitario,precioReferencia,unidadReferencia)
			VALUES (@idTipoDeProducto,@descripcionProducto,@precioUnitario,@precioReferencia,@unidadReferencia);
	END TRY
	BEGIN CATCH
		RAISERROR ('Error en el procedimiento almacenado agregarproducto. Los datos del producto son incorrectos.',16,5);
	END CATCH
END
GO
CREATE OR ALTER PROCEDURE Producto.agregarProductoConNombreTipoProd (@nombreTipoDeProducto VARCHAR(255),@descripcionProducto VARCHAR(255),
													@precioUnitario DECIMAL(10,2),@precioReferencia DECIMAL(10,2) = NULL,
													@unidadReferencia VARCHAR(255) = NULL)
AS BEGIN
	DECLARE @idTipoProducto INT;
	IF EXISTS (SELECT 5 FROM Producto.Producto WHERE descripcionProducto = @descripcionProducto)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. El producto ya existe.',16,5);
		RETURN;
	END

	IF (LEN(LTRIM(@descripcionProducto)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. La descripci�n del producto es incorrecta',16,5);
		RETURN;
	END

	IF(LEN(LTRIM(@unidadReferencia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. El precio o unidad de referencia son incorrectos.',16,5);
		RETURN;
	END

	IF(@precioReferencia IS NULL AND @unidadReferencia IS NULL)
	BEGIN
		SET @precioReferencia = @precioUnitario;
		SET @unidadReferencia = 'ud';
	END

	SET @idTipoProducto = (SELECT idTipoDeProducto FROM Producto.TipoDeProducto WHERE nombreTipoDeProducto LIKE @nombreTipoDeProducto);

	IF @idTipoProducto IS NULL
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto XD',16,5);
		RETURN;
	END

	BEGIN TRY
		INSERT INTO Producto.Producto (idTipoDeProducto,descripcionProducto,precioUnitario,precioReferencia,unidadReferencia)
			VALUES (@idTipoProducto,@descripcionProducto,@precioUnitario,@precioReferencia,@unidadReferencia);
	END TRY
	BEGIN CATCH
		RAISERROR ('Error en el procedimiento almacenado agregarproducto. Los datos del producto son incorrectos.',16,5);
	END CATCH
END
GO
--Procedimiento almacenado que permite modificar producto
--DROP PROCEDURE Producto.modificarProducto
CREATE OR ALTER PROCEDURE Producto.modificarProducto (@idProducto INT, @idTipoDeProducto INT = NULL,
													@descripcionProducto VARCHAR(255) = NULL,
													@precioUnitario DECIMAL(10,2) = NULL,
													@precioReferencia DECIMAL(10,2) = NULL,
													@unidadReferencia DECIMAL(10,2) = NULL)
AS BEGIN
	IF (@idTipoDeProducto IS NOT NULL AND 
		NOT EXISTS (SELECT 5 FROM Producto.TipoDeProducto WHERE idTipoDeProducto = @idTipoDeProducto))
		RETURN;
	IF(LEN(LTRIM(@descripcionProducto)) = 0)
	BEGIn
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El formato de la descripci�n del producto es inv�lido.',16,12);
		RETURN;
	END
	IF(LEN(LTRIM(@unidadReferencia)) = 0)
	BEGIn
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El formato de la unidadReferencia es inv�lido.',16,12);
		RETURN;
	END

	BEGIN TRY
		UPDATE Producto.Producto
			SET idTipoDeProducto = COALESCE(@idTipoDeProducto,idTipoDeProducto),
				descripcionProducto = COALESCE(@descripcionProducto,descripcionProducto),
				precioUnitario = COALESCE(@precioUnitario,precioUnitario),
				precioReferencia = COALESCE(@precioReferencia,precioReferencia),
				unidadReferencia = COALESCE(@unidadReferencia,unidadReferencia)
			WHERE idProducto = @idProducto;
	END TRY
	BEGIN CATCH
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. Los datos que se desean cambiar son inv�lidos.',16,12);
	END CATCH
END
GO
--Procedimiento almacenado que permite eliminar producto
--DROP PROCEDURE Producto.eliminarProducto
CREATE OR ALTER PROCEDURE Producto.eliminarProducto (@idProducto INT)
AS BEGIN
	UPDATE Factura.DetalleFactura
		SET idProducto = NULL
		WHERE idProducto = @idProducto

	DELETE FROM Producto.Producto
		WHERE idProducto = @idProducto;
END
GO
--	Vista para ver los productos junto a su categor�a
--	DROP VIEW Producto.VerListadoDeProductos
--	SELECT * FROM Producto.VerListadoDeProductos
CREATE OR ALTER VIEW Producto.verListadoDeProductos AS
	SELECT idProducto,precioUnitario,precioReferencia,unidadReferencia,t.nombreTipoDeProducto
		FROM Producto.Producto p JOIN Producto.TipoDeProducto t ON p.idTipoDeProducto = t.idTipoDeProducto;
GO
--	Chequear en https://dolarito.ar
--	Devuelve el valor del dolar en pesos
--	DROP PROCEDURE Producto.PasajeDolarAPesos
--	DECLARE @dolar DECIMAL(6,2); EXEC Producto.pasajeDolarAPesos @dolar OUTPUT; PRINT @dolar
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
--Tabla Tipo  de Producto
--	Procedimiento almacenado para agregar una categor�a de los productos
--	DROP PROCEDURE Producto.AgregarTipoDeProducto;
CREATE OR ALTER PROCEDURE Producto.agregarTipoDeProducto (@nombreTipoDeProducto VARCHAR(255))
AS BEGIN
	IF EXISTS (SELECT 1 FROM Producto.TipoDeProducto 
				WHERE nombreTipoDeProducto LIKE @nombreTipoDeProducto)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado "AgregarTipoDeProducto". La categor�a ya se encuentra ingresada.',16,1);
		RETURN;
	END

	IF(LEN(LTRIM(@nombreTipoDeProducto)) = 0)
	BEGIN
		RAISERROR('ERror en el procedimiento almacenado agregarTipoDeProducto. La categor�a es inv�lida.',16,6);
		RETURN;
	END

	INSERT INTO Producto.TipoDeProducto(nombreTipoDeProducto) VALUES (@nombreTipoDeProducto);
END
GO
--	Procedimiento almacenado para modificar el nombre de la categor�a
--	DROP PROCEDURE Producto.modificarTipoDeProducto
CREATE OR ALTER PROCEDURE Producto.modificarTipoDeProducto (@idTipoDeProducto INT,@nombreTipoDeProducto VARCHAR(255))
AS BEGIN
	IF (LEN(LTRIM(@nombreTipoDeProducto)) = 0)
		RETURN;
	UPDATE Producto.TipoDeProducto 
		SET nombreTipoDeProducto = COALESCE(@nombreTipoDeProducto,nombreTipoDeProducto) 
		WHERE idTipoDeProducto = @idTipoDeProducto;
END
GO
--	Procedimienot almacenado para eliminar un tipo de categor�a de los productos.
--	DROP PROCEDURE Producto.eliminarTipoDeProducto
CREATE OR ALTER PROCEDURE Producto.eliminarTipoDeProducto (@idTipoDeProducto INT)
AS BEGIN
	UPDATE Producto.Producto
		SET idTipoDeProducto = NULL
		WHERE idTipoDeProducto = @idTipoDeProducto

	DELETE FROM Producto.TipoDeProducto
		WHERE idTipoDeProducto = @idTipoDeProducto;
END;
GO
------------------------------------------------Factura------------------------------------------------
--		DROP PROCEDURE Factura.agregarFactura
/*CREATE OR ALTER PROCEDURE Factura.agregarFactura(@tipoFactura CHAR, @tipoCliente VARCHAR(10), @genero VARCHAR(10),
												@fechaHora SMALLDATETIME, @idMedioDePago INT, @legajo INT,
												@idSucursal INT, @idDePago INT,@idProducto INT,@cantidad SMALLINT)
AS BEGIN
	IF(LEN(LTRIM(@tipoCliente)) = 0 OR LEN(LTRIM(@genero)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarFactura.',16,14);
		RETURN;
	END

	INSERT INTO Factura.Factura (tipoFactura,tipoCliente,genero,fechaHora,idMedioDepago,legajo,idSucursal,identificadorDePago,idProducto,cantidad)
		VALUES (@tipoFactura,@tipoCLiente,@genero,@fechaHora,@idMedioDePago,@legajo,@idSucursal,@idDePago,@idProducto,@cantidad);

END
GO*/
-------------------------------------------------------------------------------------------------------------------
/*
Mensual: ingresando un mes y a�o determinado mostrar el total facturado por d�as de
la semana, incluyendo s�bado y domingo.
*/
--		DROP PROCEDURE Factura.exportarResumenMensual
--		EXEC Factura.exportarResumenMensual 3,2019
/*CREATE OR ALTER PROCEDURE Factura.exportarResumenMensual (@mes TINYINT, @anio SMALLINT)
AS BEGIN
	WITH VentasXDiaCTE AS
	(
		SELECT DATENAME(dw,fechaHora) AS Dia,f.cantidad * p.precioUnitario AS Venta
			FROM Factura.Factura f JOIN Producto.Producto p
				ON f.idProducto = p.idProducto
			WHERE MONTH(fechaHora) = @mes AND YEAR(fechaHora) = @anio
	), ResumenDiarioDelMesCTE AS
	(
		SELECT DISTINCT Dia,SUM(Venta) OVER(PARTITION BY Dia) AS Total FROM VentasXDiaCTE
	)
	SELECT * FROM ResumenDiarioDelMesCTE
	FOR XML RAW('Dia'), ROOT('ResumenMensual'), ELEMENTS XSINIL;
END
GO
--SELECT GETDATE()
--SELECT DATEPART(dw,GETDATE())
--SELECT DATENAME(dw,GETDATE())
/*
Trimestral: mostrar el total facturado por turnos de trabajo por mes.

	Trimestre:
		->1: Enero,Febrero,Marzo
		->2: Abril,Mayo,Junio
		->3: Julio,Agosto,Septiembre
		->4: Octubre,Noviembre,Diciembre

	Trimestre:
		->4: 10,11,12
		->3:  7, 8, 9
		->2:  4, 5, 6
		->1:  1, 2, 3
*/
--SELECT * FROM Sucursal.verTurnosDeEmpleados
--		DROP PROCEDURE Factura.exportarResumenTrimestral
--		EXEC Factura.exportarResumenTrimestral 1,2019
CREATE OR ALTER PROCEDURE Factura.exportarResumenTrimestral (@trimestre TINYINT, @anio SMALLINT)
AS BEGIN
	IF(@trimestre > 4 OR @anio < 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado exportarResumenTrimestral.',16,15);
		RETURN;
	END
	DECLARE @primerMes  TINYINT = 1,
			@segundoMes TINYINT = 2,
			@tercerMes  TINYINT = 3;

	IF (@trimestre > 1)
	BEGIN
		SET @primerMes = @primerMes + (@trimestre-1) * 3;
		SET @segundoMes = @segundoMes + (@trimestre-1) * 3;
		SET @tercerMes = @tercerMes + (@trimestre-1) * 3;
	END;
	--SELECT @primerMes,@segundoMes,@tercerMes;
	WITH ProductosVendidosXMes (legajo,Monto,Mes) AS
	(
		SELECT f.legajo,f.cantidad * p.precioUnitario,DATENAME(MONTH,fechaHora) FROM Factura.Factura f JOIN Producto.Producto p ON f.idProducto = p.idProducto
		WHERE YEAR(fechaHora) = @anio AND (MONTH(fechaHora) BETWEEN @primerMes AND @tercerMes)
	),MontoTotalXTurno AS
	(
		SELECT Mes,nombreTurno,SUM(Monto) OVER (PARTITION BY Mes, nombreTurno) AS MontoTotal
			FROM ProductosVendidosXMes p JOIN Sucursal.verTurnosDeEmpleados t
				ON p.legajo = t.legajo
	)
	SELECT DISTINCT * 
		FROM MontoTotalXTurno
		FOR XML RAW('VentaMensualXTurno'),ROOT('Trimestre'),ELEMENTS

END
GO*/
/*
Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar
la cantidad de productos vendidos en ese rango por sucursal, ordenado de mayor a
menor.
*/
--		Factura.exportarResumenRangoFechas
--		EXEC Factura.exportarResumenRangoFechas @fecha1='2019-1-15',@fecha2='2019-2-24'
/*CREATE OR ALTER PROCEDURE Factura.exportarResumenRangoFechas (@fecha1 DATE,@fecha2 DATE)
AS BEGIN
	DECLARE @fechaAux DATE;

	IF(@fecha1 IS NULL OR @fecha2 IS NULL)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado exportarResumenRangoFechas.',16,16);
		RETURN;
	END
	IF(@fecha1 > @fecha2)
	BEGIN
		SET @fechaAux = @fecha1;
		SET @fecha1 = @fecha2;
		SET @fecha2 = @fechaAux;
	END;

	WITH ProductosVendidosEnRango AS
	(
		SELECT DISTINCT idSucursal,SUM(cantidad) OVER(PARTITION BY idSucursal) AS CantVentas 
			FROM Factura.Factura
			WHERE fechaHora BETWEEN @fecha1 AND @fecha2
	)
	SELECT * FROM ProductosVendidosEnRango ORDER BY idSucursal DESC
	FOR XML RAW('CantidadDeVentasPorSucursal'),ROOT('MejoresVentas')
END
GO
--Mostrar los 5 productos m�s vendidos en un mes, por semana

--		DROP PROCEDURE Factura.mostrarTop5ProductosMasVendidosXSemana
--		EXEC Factura.mostrarTop5ProductosMasVendidosXSemana @mes=3,@anio=2019
CREATE OR ALTER Procedure Factura.mostrarTop5ProductosMasVendidosXSemana (@mes TINYINT,@anio SMALLINT)
AS BEGIN
	WITH VentaDeProductosXSemana (producto,montoDeVenta,semana) AS
	(
		SELECT p.descripcionProducto,f.cantidad * p.precioUnitario ,DATEPART(ISO_WEEK,fechaHora)
			FROM Factura.Factura f JOIN Producto.Producto p
				ON  f.idProducto = p.idProducto
			WHERE YEAR(fechaHora) = @anio AND MONTH(fechaHora) = @mes
	),VentaTotalDeProductosXSemana (Semana,Producto,MontoTotal) AS
	(
		SELECT semana,producto,SUM(montoDeVenta) OVER (PARTITION BY semana,producto ORDER BY semana) 
			FROM VentaDeProductosXSemana
	),TopVentasXSemana (semana,producto,montoTotal,TopN) AS
	(
		SELECT semana,producto,montoTotal,DENSE_RANK() OVER(PARTITION BY semana ORDER BY montoTotal DESC)
			FROM VentaTotalDeProductosXSemana
	),TopCincoVentasXSemana (Producto,Total,Semana) AS
	(
		SELECT producto,montoTotal,semana FROM TopVentasXSemana WHERE TopN < 5
	)
	SELECT Semana,Producto,Total FROM TopCincoVentasXSemana

END
GO
--Mostrar los 5 productos menos vendidos en el mes.
--		DROP PROCEDURE Factura.mostrarTop5ProductosMenosVendidosDelMes
--		EXEC Factura.mostrarTop5ProductosMenosVendidosDelMes @mes=2,@anio=2019
CREATE OR ALTER PROCEDURE Factura.mostrarTop5ProductosMenosVendidosDelMes (@mes TINYINT, @anio SMALLINT)
AS BEGIN
	WITH FacturaProductoVenta (producto,monto) AS
	(
	SELECT p.descripcionProducto,f.cantidad*p.precioUnitario
		FROM Factura.Factura f JOIN Producto.Producto p
			ON  f.idProducto = p.idProducto
		WHERE YEAR(fechaHora) = @anio AND MONTH(fechaHora) = @mes
	), MontoTotalXProducto (Producto,Monto) AS
	(
		SELECT DISTINCT producto,SUM(monto) OVER(PARTITION BY producto)
			FROM FacturaProductoVenta
	)
	SELECT TOP(5) * FROM MontoTotalXProducto ORDER BY Monto ASC
END
GO*/
/*
Mostrar total acumulado de ventas (o sea tambien mostrar el detalle) para una fecha
y sucursal particulares
	SELECT * FROM Factura.Factura;
	SELECT * FROM Factura.verFacturaDetallada;

--		EXEC Factura.exportarResumenRangoFechas @fecha1='2019-1-15',@fecha2='2019-2-24'
--		DROP PROCEDURE Factura.mostrarFacturaDetalladaXSucursalFecha
--		EXEC Factura.mostrarFacturaDetalladaXSucursalFecha @fecha='2019-1-15',@idSucursal=1;
CREATE OR ALTER PROCEDURE Factura.mostrarFacturaDetalladaXSucursalFecha (@fecha DATE, @idSucursal INT)
AS BEGIN
	WITH SucursalCiudad AS
	(
		SELECT s.idSucursal,d.localidad 
			FROM Sucursal.Sucursal s JOIN Direccion.Direccion d
				ON s.idDireccion = d.idDireccion
	),FacturaIds AS
	(
		SELECT f.idFactura,f.idMedioDepago,f.idProducto,s.localidad 
			FROM SucursalCiudad s JOIN Factura.Factura f
				ON s.idSucursal = f.idSucursal
			WHERE s.idSucursal = @idSucursal AND CAST(f.fechaHora as DATE) = @fecha
	),MedioDePagoIds AS
	(
		SELECT f.idFactura,f.idProducto,f.localidad,m.nombreMedioDePago 
			FROM FacturaIds f JOIN Factura.MedioDePago m
				ON f.idMedioDepago = m.idMedioDePago
	),ProductoIds AS
	(
		SELECT m.idFactura,m.localidad,m.nombreMedioDePago,p.descripcionProducto,
				p.idTipoDeProducto,p.precioUnitario
			FROM MedioDePagoIds m JOIN Producto.Producto p
				ON m.idProducto = p.idProducto
	),TipoDeProductoIds AS
	(
		SELECT idFactura,localidad,nombreMedioDePago,descripcionProducto,precioUnitario,nombreTipoDeProducto 
			FROM ProductoIds p JOIN Producto.TipoDeProducto t
				ON p.idTipoDeProducto = t.idTipoDeProducto
	),FacturaDetallada ([ID Factura],[Tipo de Factura],Ciudad,[Tipo De Cliente],Genero,Producto,[Categor�a],
						[Monto Acumulado],Fecha,[Medio De Pago],Empleado,[Identificador de pago]) AS
	(
		SELECT f.idFactura, f.tipoFactura,t.localidad,f.tipoCliente,f.genero,t.descripcionProducto,
				t.nombreTipoDeProducto,t.precioUnitario*f.cantidad,CAST(f.fechaHora AS DATE),
				t.nombreMedioDePago,f.legajo,f.identificadorDePago
			FROM TipoDeProductoIds t JOIN Factura.Factura f
				ON t.idFactura = f.idFactura
	)
	SELECT * FROM FacturaDetallada
END
GO
--		DROP VIEW Factura.verFacturaDetallada
--		SELECT * FROM Factura.Factura;
--		SELECT * FROM Factura.verFacturaDetallada
CREATE OR ALTER VIEW Factura.verFacturaDetallada AS
	WITH SucursalCiudad AS
	(
		SELECT s.idSucursal,d.localidad 
			FROM Sucursal.Sucursal s JOIN Direccion.Direccion d
				ON s.idDireccion = d.idDireccion
	),FacturaIds AS
	(
		SELECT f.idFactura,f.idMedioDepago,f.idProducto,s.localidad 
			FROM SucursalCiudad s JOIN Factura.Factura f
				ON s.idSucursal = f.idSucursal
	),MedioDePagoIds AS
	(
		SELECT f.idFactura,f.idProducto,f.localidad,m.nombreMedioDePago 
			FROM FacturaIds f JOIN Factura.MedioDePago m
				ON f.idMedioDepago = m.idMedioDePago
	),ProductoIds AS
	(
		SELECT m.idFactura,m.localidad,m.nombreMedioDePago,p.descripcionProducto,
				p.idTipoDeProducto,p.precioUnitario,p.precioReferencia,p.unidadReferencia
			FROM MedioDePagoIds m JOIN Producto.Producto p
				ON m.idProducto = p.idProducto
	),TipoDeProductoIds AS
	(
		SELECT idFactura,localidad,nombreMedioDePago,descripcionProducto,precioUnitario,precioReferencia,
				unidadReferencia,nombreTipoDeProducto 
			FROM ProductoIds p JOIN Producto.TipoDeProducto t
				ON p.idTipoDeProducto = t.idTipoDeProducto
	),FacturaDetallada ([ID Factura],[Tipo de Factura],Ciudad,[Tipo De Cliente],Genero,Producto,[Categor�a],
						[Precio Unitario],Cantidad,Fecha,Hora,[Medio De Pago],Empleado,[Identificador de pago]) AS
	(
		SELECT f.idFactura, f.tipoFactura,t.localidad,f.tipoCliente,f.genero,t.descripcionProducto,
				t.nombreTipoDeProducto,t.precioUnitario,f.cantidad,CAST(f.fechaHora AS DATE),
				CAST(f.fechaHora AS TIME(0)),t.nombreMedioDePago,f.legajo,f.identificadorDePago
			FROM TipoDeProductoIds t JOIN Factura.Factura f
				ON t.idFactura = f.idFactura
	)
	SELECT * FROM FacturaDetallada
GO*/