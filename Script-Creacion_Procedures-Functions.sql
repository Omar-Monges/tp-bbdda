/*
--Lista Codigo de errores:
	1 -> agregarEmpleado
	2 -> agregarSucursal
	3 -> agregarCargo
	4 -> agregarTurno

--Esquema Dirección
	verDireccionesDeEmpleados ->vemos las direcciones de los empleados
	verDireccionesDeSucursales -> vemos las direcciones de las sucursales
	
--Esquema Empleado
	calcularCUIL -> devuelve el CUIL de un empleado

	agregarEmpleado
	modificarEmpleado
	eliminarEmpleado

	verDatosEmpleados -> vemos los datos de los empleados junto a su turno,cargo y sucursal en la que trabaja.
	verDatosPersonalesDeEmpleados -> vemos los datos personales

--Esquema Sucursal
	Tabla Sucursal	
		agregarSucursal
		modificarSucursal
		eliminarSucursal

		verSucursales
		verEmpleadosDeSucursales
	Tabla Cargo
		agregarCargo
		modificarCargo
		eliminarCargo

		verCargosDeEmpleados
	Tabla Turno
		agregarTurno
		modificarTurno
		eliminarTurno

		verTurnosDeEmpleados
--Esquema Producto
	Tabla Producto
		agregarProducto
		modificarProducto
		eliminarProducto

		pasajeDolarAPesos

		verProductos ->muestra a los productos con sus categorias
	Tabla TipoDeProducto
		agregarTipoDeProducto
		modificarTipoDeProducto
		eliminarTipoDeProducto

--Esquema Factura
*/
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'G2900G19')
	USE G2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1)
GO
--USE master
--DROP DATABASE G2900G19
------------------------------------------------Esquema Dirección------------------------------------------------
--Ver los domicilios de todos los empleados.
--DROP VIEW Direccion.verDomiciliosDeEmpleados
--SELECT * FROM Direccion.verDomiciliosDeEmpleados
CREATE OR ALTER VIEW Direccion.verDomiciliosDeEmpleados AS
	SELECT e.legajo,d.* FROM Empleado.Empleado e JOIN Direccion.Direccion d ON e.idDireccion = d.idDireccion;
GO
--Ver las direcciones de todas las sucursales
--DROP VIEW Direccion.verDireccionesDeSucursales
--SELECT *  FROM Direccion.verDireccionesDeSucursales
CREATE OR ALTER VIEW Direccion.verDireccionesDeSucursales AS
	SELECT s.idSucursal,d.* FROM Sucursal.Sucursal s JOIN Direccion.Direccion d ON d.idDireccion = s.idDireccion;
GO
------------------------------------------------Esquema Empleado------------------------------------------------
--Calcula el cuil de un empleado mediante un DNI y el Sexo:
--	DROP FUNCTION Empleado.calcularCUIL		<--- ¡Primero borrar el procedure agregarEmpleado!
--	DROP PROCEDURE Empleado.agregarEmpleado
--	PRINT Empleado.calcularCUIL('42781944','M')
CREATE OR ALTER FUNCTION Empleado.calcularCUIL (@dni VARCHAR(8), @sexo CHAR(1))
RETURNS VARCHAR(13)
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
CREATE OR ALTER PROCEDURE Empleado.agregarEmpleado (@dni VARCHAR(8),@nombre VARCHAR(50),@apellido VARCHAR(50),@sexo CHAR(1),
													@emailPersonal VARCHAR(50),@emailEmpresa VARCHAR(50),@idSucursal INT,
													@idTurno INT,@idCargo INT,@calle VARCHAR(255),@numCalle SMALLINT,@codPostal SMALLINT,
													@localidad VARCHAR(255),@provincia VARCHAR(255),@piso TINYINT = NULL,@numDepto TINYINT)
AS BEGIN
	DECLARE @idDireccion INT;
	DECLARE @cuil VARCHAR(13);

	IF (@dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El DNI es inválido.',16,1);
		RETURN;
	END;

	IF (LEN(LTRIM(RTRIM(@nombre))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El Nombre es inválido.',16,1);
		RETURN;
	END;

	IF (LEN(LTRIM(RTRIM(@apellido))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El Apellido es inválido.',16,1);
		RETURN;
	END;

	IF (@sexo NOT IN ('M','F'))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El sexo es inválido.',16,1);
		RETURN;
	END

	IF (@emailPersonal NOT LIKE '%@%.com')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El Email Personal es inválido.',16,1);
		RETURN;
	END;

	IF (@emailEmpresa NOT LIKE '%@aurora.com')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El Email Empresarial tiene un formato inválido.',16,1);
		RETURN;
	END;

	IF (@idSucursal NOT IN (Select idSucursal FROM Sucursal.Sucursal))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El ID de la sucursal no existe.',16,1);
		RETURN;
	END;

	IF (@idTurno NOT IN (SELECT idTurno FROM Sucursal.Turno))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El ID del turno no existe.',16,1);
		RETURN;
	END;

	IF (@idCargo NOT IN (SELECT idCargo FROM Sucursal.Cargo))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El ID del cargo no existe.',16,1);
		RETURN;
	END;
	
	IF ((@piso IS NULL AND @numDepto IS NOT NULL) OR (@piso IS NOT NULL OR @numDepto IS NULL))
	BEGIN--Si no entra en el if es porque tanto @piso como @numDepto son nulos o no nulos.
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. La dirección es inválida.',16,1);
		RETURN;
	END;

	IF ((@piso IS NOT NULL AND @numDepto IS NOT NULL) AND (@piso < 0 OR @numDepto < 0))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. La dirección es inválida.',16,1);
		RETURN;
	END

	IF ((LEN(LTRIM(RTRIM(@calle))) = 0) OR (@numCalle<0) OR (LEN(LTRIM(RTRIM(@localidad))) = 0) 
		OR (@codPostal<0) OR LEN(LTRIM(RTRIM(@provincia))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. La direccion es inválida.',16,1);
		RETURN;
	END;
	--Buscamos si ya existe la dirección
	SET @idDireccion = (SELECT idDireccion FROM Direccion.Direccion WHERE
							@calle like calle AND numeroDeCalle = @numCalle AND codigoPostal = @codPostal AND localidad like @localidad
							AND provincia like @provincia AND piso = @piso AND departamento = @numDepto);

	IF (@idDireccion IS NULL)
	BEGIN --La direccion no existe, entonces la agregaremos!
		INSERT INTO Direccion.Direccion(calle,numeroDeCalle,codigoPostal,piso,departamento,localidad,provincia) 
					VALUES(@calle,@numCalle,@codPostal,@piso,@numDepto,@localidad,@provincia);
		--Buscamos el id de la direccion agregada
		SET @idDireccion = (SELECT TOP(1) idDireccion FROM Direccion.Direccion ORDER BY idDireccion DESC);
	END
	ELSE--@idDireccion IS NOT NULL
	BEGIN
		IF EXISTS (SELECT 1 FROM Sucursal.Sucursal WHERE idDireccion = @idDireccion)
		BEGIN
			RAISERROR('Error en el procedimiento almacenado agregarEmpleado. La dirección pertenece a una sucursal.',16,1);
			RETURN;
		END
	END;

	SET @cuil = Empleado.calcularCUIL(@dni,@sexo);

	INSERT INTO Empleado.Empleado(dni,nombre,apellido,idDireccion,emailPersonal,emailEmpresarial,idSucursal,idTurno,idCargo,cuil) 
				VALUES(@dni,@nombre,@apellido,@idDireccion,@emailPersonal,@emailEmpresa,@idSucursal,@idTurno,@idCargo,@cuil);
END;
GO
---Modificar Empleado
--DROP PROCEDURE Empleado.modificarEmpleado
CREATE OR ALTER PROCEDURE Empleado.modificarEmpleado(@legajo INT,@nombre VARCHAR(255),@apellido VARCHAR(255) = NULL,
													@emailPersonal VARCHAR(255)=NULL,@emailEmpresarial VARCHAR(255)=NULL,
													@idTurno INT=NULL,@idCargo INT=NULL,
													@calle VARCHAR(255) = NULL, @numCalle SMALLINT = NULL,@codPostal SMALLINT = NULL, 
													@localidad VARCHAR(255) = NULL, @provincia VARCHAR(255) = NULL,
													@piso TINYINT = NULL, @numDepto TINYINT = NULL)
AS BEGIN
	DECLARE @viejoIDDireccion INT,
			@cantHabitantes INT,
			@nuevoIDDireccion INT = NULL;

	IF(@legajo IS NULL OR NOT EXISTS (SELECT 1 FROM Empleado.Empleado WHERE legajo = @legajo))
		RETURN;
		
	IF(@calle IS NOT NULL OR @numCalle IS NOT NULL OR @codPostal IS NOT NULL OR @localidad IS NOT NULL OR
		@provincia IS NOT NULL OR (@piso IS NOT NULL AND @numDepto IS NOT NULL))--Se desea cambiar la dirección.
	BEGIN
		--Chequeamos si algún otro empleado ya vive en la vieja dirección.
		SET @viejoIDDireccion = (SELECT idDireccion FROM Empleado.Empleado WHERE legajo = @legajo);
		SET @cantHabitantes = (SELECT COUNT(idDireccion) FROM Empleado.Empleado WHERE idDireccion = @viejoIDDireccion);

		IF (@cantHabitantes = 1)
		BEGIN
			UPDATE Empleado.Empleado
					SET idDireccion = NULL
					WHERE legajo = @legajo;
			DELETE FROM Direccion.Direccion WHERE idDireccion = @viejoIDDireccion;
		END

		IF NOT EXISTS (SELECT 1 FROM Direccion.Direccion 
						WHERE calle = @calle AND numeroDeCalle = @numCalle AND codigoPostal = @codPostal AND localidad = @localidad
								AND provincia = @provincia AND piso = @piso AND departamento = @numDepto)
		BEGIN--La dirección que se desea modificar no pertenece a ningún otro empleado.
			INSERT INTO Direccion.Direccion(calle,numeroDeCalle,codigoPostal,localidad,provincia,piso,departamento)
					VALUES(@calle,@numCalle,@codPostal,@localidad,@provincia,@piso,@numDepto);
			SET @nuevoIDDireccion = (SELECT TOP(1) idDireccion FROM Direccion.Direccion ORDER BY idDireccion DESC)
		END
	END

	UPDATE Empleado.Empleado
			SET nombre = COALESCE(@nombre,nombre),
				apellido = COALESCE(@apellido,apellido),
				emailPersonal = COALESCE(@emailPersonal,emailPersonal),
				emailEmpresarial = COALESCE(@emailEmpresarial,emailEmpresarial),
				idTurno = COALESCE(@idTurno,idTurno),
				idCargo = COALESCE(@idCargo,idCargo),
				idDireccion = COALESCE(@nuevoIDDireccion,idDireccion)
			WHERE legajo = @legajo;
END
GO
--Eliminar Empleado
--DROP PROCEDURE Empleado.eliminarEmpleado
CREATE OR ALTER PROCEDURE Empleado.eliminarEmpleado(@legajo INT)
AS BEGIN
	DECLARE @cantHabitantes TINYINT;
	DECLARE @idDireccion INT;

	IF (@Legajo IS NULL OR NOT EXISTS (SELECT 1 from Empleado.Empleado where legajo = @legajo))
		RETURN;
	--Eliminamos solamente el legajo de los empleados en las facturas.
	UPDATE Factura.Factura
			SET legajoEmpleado = NULL
			WHERE legajoEmpleado = @legajo;
	
	SET @idDireccion = (SELECT idDireccion FROM Empleado.Empleado WHERE legajo = @legajo)
	SET @cantHabitantes = (SELECT COUNT(idDireccion) FROM Empleado.Empleado WHERE idDireccion = @idDireccion);
		
	ALTER TABLE Empleado.Empleado
		DROP CONSTRAINT PK_Empleado;

	DELETE FROM Empleado.Empleado
				WHERE legajo = @legajo;

	ALTER TABLE Empleado.Empleado
		ADD CONSTRAINT PK_Empleado PRIMARY KEY(legajo);

	IF (@cantHabitantes = 1)
	BEGIN
		DELETE FROM Direccion.Direccion
					WHERE idDireccion = @idDireccion;
	END	
END
GO
--Ver toda la tabla de empleados junto a su turno,cargo y sucursal en la que trabaja.
--DROP VIEW Empleado.verEmpleados
--SELECT * FROM Empleado.verDatosDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosDeEmpleados AS
	WITH EmpleadoCTE AS
	(
		SELECT legajo,idSucursal,idCargo,idTurno
			FROM Empleado.Empleado
	),CargoEmpleado (legajo,idSucursal,idTurno,cargo) AS
	(
		SELECT e.legajo,e.idSucursal,e.idTurno,c.nombreCargo 
			FROM Sucursal.cargo c JOIN EmpleadoCTE e ON c.idCargo = e.idCargo
	),SucursalEmpleado (legajo,idTurno,cargo,localidadSucursal) AS
	(
		SELECT legajo,idTurno,cargo,d.localidad
			FROM 
			(
				SELECT legajo,idTurno,s.idDireccion,cargo 
					FROM Sucursal.Sucursal s JOIN CargoEmpleado c ON s.idSucursal = c.idSucursal
			) AS T JOIN Direccion.Direccion d ON d.idDireccion = T.idDireccion
	),TurnoEmpleado (legajo,cargo,localidadSucursal,turno) AS
	(
		SELECT Legajo,cargo,localidadSucursal,t.nombreTurno 
			FROM Sucursal.Turno t JOIN SucursalEmpleado e ON t.idTurno = e.idTurno
	),DatosEmpleado AS
	(
		SELECT Empl.*,t.cargo,t.localidadSucursal,t.turno
		FROM
		(
			SELECT e.legajo,e.cuil,e.apellido,e.nombre,e.emailPersonal,e.emailEmpresarial,d.calle,
					d.numeroDeCalle,COALESCE(d.Piso,'-') AS Piso,COALESCE(d.departamento,'-') AS Departamento,
					d.codigoPostal,d.localidad AS Ciudad
				FROM Empleado.Empleado e JOIN Direccion.Direccion d ON e.idDireccion = e.idDireccion
		) AS Empl JOIN TurnoEmpleado t ON Empl.legajo = t.legajo
	)
	SELECT * FROM DatosEmpleado;
GO
--Ver los datos personales de los empleados
--DROP VIEW Empleado.verDatosPersonalesDeEmpleados
--SELECT * FROM Empleado.verDatosPersonalesDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosPersonalesDeEmpleados AS
	SELECT e.legajo,e.apellido,e.nombre,e.cuil,e.emailEmpresarial,e.emailPersonal,
			d.calle,d.numeroDeCalle,d.codigoPostal,COALESCE(d.piso,'-') AS Piso,COALESCE(d.departamento,'-') AS Departamento
		FROM Empleado.Empleado  e JOIN Direccion.Direccion d ON e.idDireccion = d.idDireccion
GO
------------------------------------------------Esquema Sucursal------------------------------------------------
--Tabla Sucursal
--	Procedimiento almacenado que permite agregar una sucursal.
--	DROP PROCEDURE Sucursal.agregarSucursal
CREATE OR ALTER PROCEDURE Sucursal.agregarSucursal (@telefono VARCHAR(9),@horario VARCHAR(255),
													@calle VARCHAR(255),@numeroDeCalle SMALLINT,@codPostal SMALLINT,
													@localidad VARCHAR(255),@provincia VARCHAR(255))
AS BEGIN
	DECLARE @idDireccion INT;

	IF(@telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Error en el procedimiento agregarSucursal. El teléfono es inválido.',16,2);
		RETURN;
	END

	IF(LEN(LTRIM(RTRIM(@horario))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El horario es inválido.',16,2);
		RETURN;
	END

	IF(LEN(LTRIM(RTRIM(@calle))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La calle es inválida.',16,2);
		RETURN;
	END

	IF(@numeroDeCalle < 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. el numero de la calle es inválida',16,2);
		RETURN;
	END

	IF(@codPostal < 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El código postal es inválido.',16,2);
		RETURN;
	END

	IF(LEN(LTRIM(RTRIM(@localidad))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La localidad es inválida.',16,2);
	END

	IF(LEN(LTRIM(RTRIM(@provincia))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La provincia es inválida.',16,2);
	END
	--Buscamos si ya existe la dirección
	SET @idDireccion = (SELECT idDireccion FROM Direccion.Direccion 
						WHERE calle like @calle AND numeroDeCalle = @numeroDeCalle AND codigoPostal = @codPostal AND
						localidad like @localidad AND provincia like @provincia);

	IF (@idDireccion IS NOT NULL)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La dirección ya existe.',16,2);
		RETURN;
	END
	
	INSERT INTO Direccion.Direccion (calle,numeroDeCalle,codigoPostal,localidad,provincia) 
			VALUES (@calle,@numeroDeCalle,@codPostal,@localidad,@provincia);
	SET @idDireccion = (SELECT TOP(1) idDireccion FROM Direccion.Direccion ORDER BY idDireccion DESC);
	
	INSERT INTO Sucursal.Sucursal (telefono,horario,idDireccion)
			VALUES (@telefono,@horario,@idDireccion);
END
GO
--	Procedimiento almacenado que permite modificar una sucursal.
--	DROP PROCEDURE Sucursal.modificarSucursal
CREATE OR ALTER PROCEDURE Sucursal.modificarSucursal (@idSucursal INT,@telefono VARCHAR(9) = NULL,
													@horario VARCHAR(255) = NULL,@calle VARCHAR(255) = NULL,
													@numeroDeCalle SMALLINT = NULL,@codPostal SMALLINT = NULL,
													@localidad VARCHAR(255) = NULL,@provincia VARCHAR(255) = NULL)
AS BEGIN
	DECLARE @idDireccion INT = NULL;

	IF NOT EXISTS (SELECT 1 FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal)
		RETURN;

	IF(LEN(LTRIM(RTRIM(@calle))) > 0 OR @numeroDeCalle >= 0 OR @codPostal >= 0 OR 
		LEN(LTRIM(RTRIM(@localidad))) > 0 OR LEN(LTRIM(RTRIM(@provincia))) > 0)
	BEGIN
		--Buscamos si ya existe la dirección.
		SET @idDireccion = (SELECT idDireccion FROM Direccion.Direccion
							WHERE calle LIKE @calle AND numeroDeCalle = @numeroDeCalle AND 
							codigoPostal = @codPostal AND localidad LIKE @localidad AND provincia LIKE @provincia);
		IF (@idDireccion IS NULL)
			RETURN;
		ELSE
		BEGIN--@idDireccion IS NOT NULL
			INSERT INTO Direccion.Direccion (calle,numeroDeCalle,codigoPostal,localidad,provincia)
					VALUES (@calle,@numeroDeCalle,@codPostal,@localidad,@provincia);
			SET @idDireccion = (SELECT TOP(1) idDireccion FROM Direccion.Direccion ORDER BY idDireccion DESC);
		END
	END

	UPDATE Sucursal.Sucursal
		SET telefono = COALESCE(@telefono,telefono),
			idDireccion = COALESCE(@idDireccion,idDireccion),
			horario = COALESCE(@horario,horario)
		WHERE idSucursal = @idSucursal;
END;
GO
--	Procedimiento almacenado que permite eliminar una sucursal.
--	DROP PROCEDURE Sucursal.eliminarSucursal
CREATE OR ALTER PROCEDURE Sucursal.eliminarSucursal (@idSucursal INT)
AS BEGIN
	DECLARE @idDireccion INT;

	SET @idDireccion = (SELECT idDireccion FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal);

	ALTER TABLE Sucursal.Sucursal
		DROP CONSTRAINT FK_Sucursal_Direccion;
	DELETE FROM Direccion.Direccion
		WHERE idDireccion = @idDireccion;
	ALTER TABLE Sucursal.Sucursal
		ADD CONSTRAINT FK_Sucursal_Direccion FOREIGN KEY(idDireccion) REFERENCES Direccion.Direccion(idDireccion);

	ALTER TABLE Empleado.Empleado
		DROP CONSTRAINT FK_Empleado_Sucursal;
	DELETE FROM Sucursal.Sucursal
		WHERE idSucursal = @idSucursal;
	ALTER TABLE Empleado.Empleado
		ADD CONSTRAINT FK_Empleado_Sucursal FOREIGN KEY(idSucursal) REFERENCES Sucursal.Sucursal(idSucursal);	
END
GO
--	Vista que permite ver la información de cada sucursal.
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
						WHERE nombreCargo = @nombreCargo COLLATE Modern_Spanish_CI_AI)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarCargo. el cargo ya se encuentra ingresado',16,3);
		RETURN;
	END

	INSERT Sucursal.Cargo (nombreCargo) VALUES (@nombreCargo);
END
GO
--	Procedimiento almacenado que permite modificar un cargo
--	DROP PROCEDURE Sucursal.modificarCargo
CREATE OR ALTER PROCEDURE Sucursal.modificarCargo (@idCargo INT,@nombreCargo VARCHAR(255))
AS BEGIN
	IF (LEN(LTRIM(RTRIM(@nombreCargo))) = 0)
		RETURN;
	UPDATE Sucursal.Cargo
		SET nombreCargo = COALESCE(@nombreCargo,nombreCargo)
		WHERE idCargo = @idCargo;
END
GO
--	Procedimiento almacenado que permite eliminar un cargo
--	DROP PROCEDURE Sucursal.eliminarCargo
CREATE OR ALTER PROCEDURE Sucursal.eliminarCargo (@idCargo INT)
AS BEGIN
	ALTER TABLE Empleado.Empleado
		DROP CONSTRAINT FK_Empleado_Cargo;

	DELETE FROM Sucursal.Cargo
		WHERE idCargo = @idCargo;

	ALTER TABLE Empleado.Empleado
		ADD CONSTRAINT FK_Empleado_Cargo FOREIGN KEY (idCargo) REFERENCES Sucursal.Cargo(idCargo);
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
					WHERE nombreTurno = @nombreTurno COLLATE Modern_Spanish_CI_AI)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarTurno.',16,4);
		RETURN;
	END

	INSERT INTO Sucursal.Turno (nombreTurno) VALUES (@nombreTurno);
END
SELECT * FROM Sucursal.Turno
GO
--	Procedimiento almacenado que permite modificar un turno
--	DROP PROCEDURE Sucursal.modificarTurno
CREATE OR ALTER PROCEDURE Sucursal.modificarTurno (@idTurno INT, @nombreTurno VARCHAR(255) = NULL)
AS BEGIN
	IF (LEN(LTRIM(RTRIM(@nombreTurno))) = 0)
		RETURN;

	UPDATE Sucursal.Turno
		SET nombreTurno = COALESCE(@nombreTurno,nombreTurno)
		WHERE idTurno = @idTurno;
END
GO
--	Procedimiento almacenado qeu permite eliminar un turno
--	DROP PROCEDURE Sucursal.eliminarTurno
CREATE OR ALTER PROCEDURE Sucursal.eliminarTurno (@idTurno INT)
AS BEGIN
	ALTER TABLE Empleado.Empleado
		DROP CONSTRAINT FK_Empleado_Turno;

	DELETE FROM Sucursal.Turno WHERE idTurno = @idTurno;

	ALTER TABLE Empleado.Empleado
		ADD CONSTRAINT FK_Empleado_Turno FOREIGN KEY (idTurno) REFERENCES Sucursal.Turno (idTurno);
END
GO
--Vista que permite ver los turnos que tiene cada empleado.
--DROP VIEW Sucursal.verTurnosDeEmpleados
--SELECT * FROM Sucursal.verTurnosDeEmpleados
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
	print 'xd'
END
GO
--Procedimiento almacenado que permite modificar producto
--DROP PROCEDURE Producto.modificarProducto
CREATE OR ALTER PROCEDURE Producto.modificarProducto
AS BEGIN
	print 'xd'
END
GO
--Procedimiento almacenado que permite eliminar producto
--DROP PROCEDURE Producto.eliminarProducto
CREATE OR ALTER PROCEDURE Producto.eliminarProducto (@idProducto INT)
AS BEGIN
	ALTER TABLE Factura.DetalleFactura
		DROP CONSTRAINT FK_DetalleFactura_Producto;

	DELETE FROM Producto.Producto
		WHERE idProducto = @idProducto;

	ALTER TABLE Producto.DetalleFactura
		ADD CONSTRAINT FK_DetalleFactura_Producto FOREIGN KEY (idProducto) 
			REFERENCES Factura.DetalleFactura (idProducto);
END
GO
--	Vista para ver los productos junto a su categoría
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
--	Procedimiento almacenado para agregar una categoría de los productos
--	DROP PROCEDURE Producto.AgregarTipoDeProducto;
CREATE OR ALTER PROCEDURE Producto.agregarTipoDeProducto (@nombreTipoDeProducto VARCHAR(255))
AS BEGIN
	IF EXISTS (SELECT 1 FROM Producto.TipoDeProducto 
				WHERE @nombreTipoDeProducto LIKE @nombreTipoDeProducto COLLATE Modern_Spanish_CI_AI)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado "AgregarTipoDeProducto". La descripción ya se encuentra ingresada.',16,1);
		RETURN;
	END
	INSERT INTO Producto.TipoDeProducto(nombreTipoDeProducto) VALUES (@nombreTipoDeProducto);
END
GO
--	Procedimiento almacenado para modificar el nombre de la categoría
--	DROP PROCEDURE Producto.modificarTipoDeProducto
CREATE OR ALTER PROCEDURE Producto.modificarTipoDeProducto (@idTipoDeProducto INT,@nombreTipoDeProducto VARCHAR(255))
AS BEGIN
	IF NOT EXISTS (SELECT 1 FROM Producto.TipoDeProducto WHERE idTipoDeProducto = @idTipoDeProducto)
		RETURN;
	IF (@nombreTipoDeProducto IS NULL OR LEN(LTRIM(RTRIM(@nombreTipoDeProducto))) = 0)
		RETURN;
	UPDATE Producto.TipoDeProducto 
		SET nombreTipoDeProducto = @nombreTipoDeProducto 
		WHERE idTipoDeProducto = @idTipoDeProducto;
END
GO
--	Procedimienot almacenado para eliminar un tipo de categoría de los productos.
--	DROP PROCEDURE Producto.eliminarTipoDeProducto
CREATE OR ALTER PROCEDURE Producto.eliminarTipoDeProducto (@idTipoDeProducto INT)
AS BEGIN
	IF NOT EXISTS (SELECT 1 FROM Producto.TipoDeProducto WHERE idTipoDeProducto = @idTipoDeProducto)
		RETURN;

	UPDATE Producto.Producto
		SET idTipoDeProducto = NULL
		WHERE idTipoDeProducto = @idTipoDeProducto;

	ALTER TABLE Producto.TipoDeProducto
		DROP CONSTRAINT PK_TipoDeProducto

	DELETE FROM Producto.TipoDeProducto
		WHERE idTipoDeProducto = @idTipoDeProducto;

	ALTER TABLE Producto.TipoDeProducto
		ADD CONSTRAINT PK_TipoDeProducto PRIMARY KEY(idTipoDeProducto);
END
GO