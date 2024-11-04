USE Com2900G19
GO
-- use master
/*
SELECT * FROM Empleado.Empleado
SELECT * FROM Direccion.Direccion
SELECT * FROM Sucursal.Sucursal
SELECT * FROM Sucursal.Cargo
SELECT * FROM Sucursal.Turno
*/
------------------------------------------------Esquema Dirección------------------------------------------------
/*
Se probará con el procedure Empleado.agregarEmpleado
Formato:
	EXEC Empleado.agregarEmpleado DNI,Nombre,Apellido,Sexo,EmailPersonal,EmailEmpresarial,IDSucursal,IDTurno,IDCargo,
									NombreCalle,NumeroDeCalle,CodigoPostal,Localidad,Provincia,Piso,NumeroDeDepartamento

SELECT * FROM Direccion.Direccion
->1) Agregamos una calle nula:
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								NULL,'3140','1333','Rosario','Santa Fé', NULL, NULL			--<--- Salida esperada: Error
->2) Agregamos una calle vacía:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'              ','3140','1333','Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
->3) Agregamos un numero de calle vacío:	<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'nombreDeCalleXD','3140','1333','Rosario','Santa Fé', NULL, NULL	--<--- Salida esperada: Error
->4) Agregamos un numero de calle negativo:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','-314','1333','Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
->5) Agregamoso un codigo postal NULO
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140',NULL,'Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
->6) Agregamos un código postal vacío
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','       ','Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
->7) Agregamos una localidad NULA (Es lo mismo con Provincia):
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333',NULL,'Santa Fé', NULL, NULL		--<--- Salida esperada: Error
->8) Agregamos una localidad vacía (es lo mismo  con Provincia):
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','      ','Santa Fé', NULL, NULL		--<--- Salida esperada: Error

->9) Agregamos un departamento pero un piso NULO (es lo mismo al revés): 
EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','Rosario','Santa Fé', NULL, 5		--<--- Salida esperada: Error
*/
GO
------------------------------------------------Esquema Sucursal------------------------------------------------
/*
--Pruebas de Turno:
SELECT * FROM Sucursal.Turno
->1) Agregamos un turno NULO
	EXEC Sucursal.agregarTurno NULL		<--- Salida esperada: ERROR
->2) Agregamos un turno vacío
	EXEC Sucursal.agregarTurno '     '		<--- Salida esperada: ERROR
->2) Agregamos un turno X:
	EXEC Sucursal.agregarTurno 'Jornada Completa'		<--- Salida esperada: Todo ok
	EXEC Sucursal.agregarTurno 'Noche'
->3) Agregamos un turno que ya existe (el del item 2):
	EXEC Sucursal.agregarTurno 'jOrNaDa COMpleTA'		<--- Salida esperada: 'El turno ya ha ingresado'
->4) Modificamos el turno de un id que no existe:
	EXEC Sucursal.modificarTurno 99,'Dia'		<--- Salida Esperada: Todo_ok (No hay cambios en la tabla)
->5) Modificamos el turno a NULL:
	EXEC Sucursal.modificarTurno 2,NULL		<--- Salida Esperada: Error
->6) Modificamos el turno a una cadena vacía:
	EXEC Sucursal.modificarTurno 2,'          '		<--- Salida Esperada: Error
->7) Eliminamos un id que no existe:
	EXEC Sucursal.eliminarTurno 99		<--- Salida Esperada: Todo_ok (No hay cambios)
->8) Eliminamos un id que existe:
	EXEC Sucursal.eliminarTurno 1		<--- Salida Esperada: Todo_ok (Se eliminó un registro)

--Prueba de Cargo:
SELECT * FROM Sucursal.Cargo
->1) Agregamos un cargo NULO
	EXEC Sucursal.agregarCargo NULL		<--- Salida esperada: ERROR
->2) Agregamos un cargo vacío
	EXEC Sucursal.agregarCargo '     '		<--- Salida esperada: ERROR
->2) Agregamos un cargo X:
	EXEC Sucursal.agregarCargo 'El de informática'		<--- Salida esperada: Todo ok
->3) Agregamos un cargo que ya existe (el del item 2):
	EXEC Sucursal.agregarCargo 'eL DE InFORmáTica'		<--- Salida esperada: 'El turno ya ha ingresado'

--Prueba de Sucursal:
SELECT * FROM Sucursal.Sucursal
SELECT * FROM Direccion.Direccion
->1) Agregamos un telefono NULO:
	EXEC Sucursal.agregarSucursal NULL,'L-V 8-21','EstoEsUnaCalle','173','1757','Morón','Buenos Aires'		<--- Salida esperada: ERROR
->2) Agregamos un telefono que no respete el formato:
	EXEC Sucursal.agregarSucursal '5555$5555','L-V 8-21','EstoEsUnaCalle','173','1757','Morón','Buenos Aires'		<--- Salida esperada: ERROR
->3) Agregamos un horario NULO:
	EXEC Sucursal.agregarSucursal '1234-5678',NULL,'EstoEsUnaCalle','173','1757','Morón','Buenos Aires'		<--- Salida esperada: ERROR
->4) Agregamos un horario vacío:
	EXEC Sucursal.agregarSucursal '1234-5678','     ','EstoEsUnaCalle','173','1757','Morón','Buenos Aires'		<--- Salida esperada: ERROR
->5) Agregamos una sucursal:
	EXEC Sucursal.agregarSucursal '1234-5678','L-V 8-21','EstoEsUnaCalle','173','1757','Morón','Buenos Aires'		<--- Salida esperada: Todo_ok
	EXEC Sucursal.agregarSucursal '8765-4321','M-S 10-22','EstoEsUnaAvenida','11','12334B','Palermo','CABA'		<--- Salida esperada: Todo_ok
SELECT * FROM Sucursal.verDatosDeSucursales
*/
GO
------------------------------------------------Esquema Empleado------------------------------------------------
/*
SELECT * FROM Empleado.Empleado
SELECT * FROM Direccion.Direccion
SELECT * FROM Sucursal.Sucursal
SELECT * FROM Sucursal.Cargo
SELECT * FROM SUcursal.Turno
->1) Agregamos un DNI NULL:
	EXEC Empleado.agregarEmpleado NULL,'Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','Rosario','Santa Fé', NULL, NULL

->2) Agregamos un DNI vacío
	EXEC Empleado.agregarEmpleado '     ','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','Rosario','Santa Fé', NULL, NULL
->3) Agregamos un nombre NULL (es lo mismo con apellido):
	EXEC Empleado.agregarEmpleado '42781944',NULL,'Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','Rosario','Santa Fé', NULL, NULL
->4) Agregamos un nombre vacío (es lo mismo con apellido):
	EXEC Empleado.agregarEmpleado '42781944','           ','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','Rosario','Santa Fé', NULL, NULL
->5) Agregamos un sexo que no esté dentro de los parámetros:
	EXEC Empleado.agregarEmpleado '42781944','Ezequiel','Calaz','Y','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','Rosario','Santa Fé', NULL, NULL
->6) Agregamos un email que no cumpla con el formato:
	EXEC Empleado.agregarEmpleado '42781944','Ezequiel','Calaz','M','topicos$hotmail:com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','Rosario','Santa Fé', NULL, NULL
->7) Agregamos dos empleados:
	EXEC Empleado.agregarEmpleado '42781944','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','Rosario','Santa Fé', NULL, NULL
	EXEC Empleado.agregarEmpleado '18652923','Ana','García','F','algoritmos@hotmail.com','yDatos@superA.com',18,3,1,
								'Rio Cuarto','11','9564C','La Plata','Buenos Aires', 4, 11

SELECT * FROM Empleado.verDatosDeEmpleados
SELECT * FROM Empleado.verDatosPersonalesDeEmpleados
SELECT * FROM Sucursal.verTurnosDeEmpleados
SELECT * FROM Sucursal.verCargoDeEmpleados
SELECT * FROM Sucursal.verEmpleadosDeCadaSucursal
*/
--Archivo Informacion_Complementaria.xlsx

--Agregamos Sucursales
--SELECT * FROM Sucursal.Sucursal
--SELECT * FROM Direccion.Direccion
EXEC Sucursal.agregarSucursal '5555-5551','L a V 8a.m.-9p.m. S y D 9a.m-8p.m.','Av. Brig. Gral. Juan Manuel de Rosas',
								3634,'B1754','San Justo','Buenos Aires';
EXEC Sucursal.agregarSucursal '5555-5552','L a V 8a.m.-9p.m. S y D 9a.m-8p.m.','Av. de Mayo 791',
								791,'B1704','Ramos Mejía','Buenos Aires';
EXEC Sucursal.agregarSucursal '5555-5553','L a V 8a.m.-9p.m. S y D 9a.m-8p.m.','Pres. Juan Domingo Perón',
								763,'B1753AWO','Lomas del Mirador','Buenos Aires';
GO
--Agregamos Medios de pagos
--EXEC Factura.archcomplementario_importarMedioDePago 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx';
--SELECT * FROM Factura.MedioDePago
--DROP PROCEDURE ArchComplementario_importarMedioDePago
CREATE OR ALTER PROCEDURE Factura.ArchComplementario_importarMedioDePago (@ruta NVARCHAR(MAX))
AS BEGIN
	
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT Factura.MedioDePago (nombreMedioDePago,descripcion) ';

	SET @SqlDinamico = @SqlDinamico + ' SELECT F2,F3
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [medios de pago$]'')'

	EXECUTE sp_executesql @SqlDinamico;
END;
GO
EXEC Factura.archcomplementario_importarMedioDePago 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx';
GO
--Agregamos Turnos
EXEC Sucursal.agregarTurno 'Turno Mañana';
EXEC Sucursal.agregarTurno 'Turno Tarde';
EXEC Sucursal.agregarTurno 'Jornada Completa';
GO
--Agregamos Cargos
EXEC Sucursal.agregarCargo 'Cajero';
EXEC Sucursal.agregarCargo 'Supervisor';
EXEC Sucursal.agregarCargo 'Gerente de sucursal';
GO
--Agregamos Empleados
/*
SELECT * FROM Sucursal.Cargo
SELECT * FROM Sucursal.Sucursal
SELECT * FROM Sucursal.Turno
SELECT * FROM Direccion.Direccion
SELECT * FROM Empleado.Empleado
*/
EXEC Empleado.agregarEmpleado '36383025','Romina Alejandra','Alias','F','Romina Alejandra_ALIAS@gmail.com','Romina Alejandra.ALIAS@superA.com',2,1,1,'Bernando de Irigoyen',2647,NULL,'San Isidro','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '31816587','Romina Soledad','Rodriguez','F','Romina Soledad_RODRIGUEZ@gmail.com','Romina Alejandra.ALIAS@superA.com',2,2,1,'Av. Vergara',1910,NULL,'Hurlingham','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '30103258','Sergio Elio','Rodriguez','M','Sergio Elio_RODRIGUEZ@gmail.com','Sergio Elio.RODRIGUEZ@superA.com',3,1,1,'Av. Belgrano',422,NULL,'Avellaneda','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '41408274','Christian Joel','Rojas','M','Christian Joel_ROJAS@gmail.com','Christian Joel.ROJAS@superA.com',3,2,1,'Calle 7',767,'-','La Plata','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '30417854','María Roberta de los Angeles','Rolon Gamarra','F','María Roberta de los Angeles_ROLON GAMARRA@gmail.com','María Roberta de los Angeles.ROLON GAMARRA@superA.com',1,1,1,'Av Arturo Illia',3770,NULL,'Malvinas Argentinas','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '29943254','Rolando','Lopez','M','Rolando_LOPEZ@gmail.com','@Rolando.LOPEZ@superA.com',1,2,1,'Av. Rivadavia',6538,NULL,'Ciudad Autónoma de Buenos Aires','Ciudad Autónoma de Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '37633159','Francisco Emmanuel','Lucena','M','Francisco Emmanuel_LUCENA@gmail.com','Francisco Emmanuel.LUCENA@superA.com',2,1,2,'Av. Don Bosco',2680,NULL,'San Justo','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '30338745','Eduardo Matias','Luna','M','Eduardo Matias _LUNA @gmail.com','Eduardo Matias .LUNA @superA.com',3,1,2,'Av. Santa Fe',1954,NULL,'Ciudad Autónoma de Buenos Aires','Ciudad Autónoma de Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '34605254','Mauro Alberto','Luna','M','Mauro Alberto_LUNA@gmail.com','Mauro Alberto.LUNA@superA.com',1,1,2,'Av. San Martín',420,NULL,'San Martín','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '36508254','Emilce','Maidana','F','Emilce_MAIDANA@gmail.com','Emilce.MAIDANA@superA.com',2,2,2,'Independencia',3067,NULL,'Carapachay','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '34636354','Noelia Gisela Fabiola','Maidana','F','NOELIA GISELA FABIOLA_MAIDANA@gmail.com','NOELIA GISELA FABIOLA.MAIDANA@superA.com',3,2,2,'Bernando de Irigoyen',2647,NULL,'San Isidro','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '33127114','Fernanda Gisela Evangelina','Maizares','F','Fernanda Gisela Evangelina_MAIZARES@gmail.com','Fernanda Gisela Evangelina.MAIZARES@superA.com',1,2,2,'Av. Rivadavia',2243,NULL,'Ciudad Autónoma de Buenos Aires','Ciudad Autónoma de Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '39231254','Oscar Martín','Ortiz','M','Oscar Martín_ORTIZ@gmail.com','Oscar Martín.ORTIZ@superA.com',2,3,3,'Juramento',2971,NULL,'Ciudad Autónoma de Buenos Aires','Ciudad Autónoma de Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '30766254','Débora','Pachtman','F','Débora_PACHTMAN@gmail.com','Débora.PACHTMAN@superA.com',3,3,3,'Av. Presidente Hipólito Yrigoyen',299,NULL,'Provincia de Buenos Aires','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '38974125','Romina Natalia','Padilla','F','Romina Natalia_PADILLA@gmail.com','Romina Natalia.PADILLA@superA.com',1,3,3,'Lacroze',5910,NULL,'Chilavert','Buenos Aires',NULL,NULL;
GO
SELECT * FROM Empleado.Empleado
/*
EXEC Empleado.ArchComplementario_importarEmpleado 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx';
*/
--SELECT * FROM Factura.MedioDePago
--DROP PROCEDURE Empleado.ArchComplementario_importarEmpleado
/*
CREATE OR ALTER PROCEDURE Empleado.ArchComplementario_importarEmpleado (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @cuilAux VARCHAR(13);
	DECLARE @codigoPostalAux VARCHAR(10);
	DECLARE @sexoAux CHAR;
	DECLARE @dniAux VARCHAR(8);
	DECLARE @ciudadAux VARCHAR(MAX)
	CREATE TABLE #tablaAux
	(
		Legajo NVARCHAR(MAX),
		Nombre NVARCHAR(MAX),
		Apellido NVARCHAR(MAX),
		DNI NVARCHAR(MAX),
		sexo NVARCHAR(MAX),
		Direccion NVARCHAR(MAX),
		emailPersonal NVARCHAR(MAX),
		emailEmpresarial NVARCHAR(MAX),
		CUIL NVARCHAR(MAX),
		Cargo NVARCHAR(MAX),
		Sucursal NVARCHAR(MAX),
		Turno NVARCHAR(MAX),
	)
	CREATE TABLE #TablaDireccionAux
	(
		Legajo NVARCHAR(MAX),
		calle NVARCHAR(MAX),
		numeroDeCalle NVARCHAR(MAX),
		codigoPostal NVARCHAR(MAX),
		localidad NVARCHAR(MAX),
		provincia NVARCHAR(MAX)
	)
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = N'INSERT #tablaAux ';

	SET @SqlDinamico = @SqlDinamico + ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [Empleados$]'')'

	EXECUTE sp_executesql @SqlDinamico;
	
	DELETE FROM #tablaAux WHERE Legajo IS NULL;
	INSERT INTO #TablaDireccionAux (Legajo,calle,numeroDeCalle,localidad,provincia)
		SELECT	LTRIM(RTRIM(Legajo)),
				LTRIM(RTRIM(SUBSTRING(Direccion,1,CHARINDEX(',',Direccion,1) - 6))) AS Calle,
				RIGHT(SUBSTRING(Direccion,1,CHARINDEX(',',Direccion,1) - 1),5) AS NumDeCalle,
				LTRIM(RTRIM(SUBSTRING(Direccion,CHARINDEX(',',Direccion,1) + 1, CHARINDEX(',',SUBSTRING(Direccion,CHARINDEX(',',Direccion,1) + 1, 100),1) - 1))) AS Localidad,
				LTRIM(RTRIM(REVERSE(SUBSTRING(REVERSE(Direccion),1,CHARINDEX(',',REVERSE(Direccion),1)  -2)))) AS Provincia
			FROM #tablaAux;
	DECLARE @cursorAux NVARCHAR(MAX);
	DECLARE	@i INT = 1;
	SET @SqlDinamico = '';
	SET @cursorAux = (SELECT TOP(1) legajo FROM 
									(SELECT Legajo,ROW_NUMBER() OVER(ORDER BY legajo) as rowNum
									FROM #TablaDireccionAux) as x WHERE rowNum = 1);

	WHILE @cursorAux IS NOT NULL
	BEGIN
		SELECT @sexoAux = Sexo,@dniAux = DNI FROM #tablaAux WHERE @cursorAux = legajo;
		EXEC @cuilAux = Empleado.calcularCUIL @dniAux,@sexoAux;
		update #tablaAux
			SET CUIL = @cuilAux
			WHERE legajo = @cursorAux;

		SET @ciudadAux = (SELECT localidad FROM #TablaDireccionAux WHERE legajo = @cursorAux);

		SET @ciudadAux = REPLACE(@ciudadAux,'á','a');
		SET @ciudadAux = REPLACE(@ciudadAux,'é','e');
		SET @ciudadAux = REPLACE(@ciudadAux,'í','i');
		SET @ciudadAux = REPLACE(@ciudadAux,'ó','o');
		SET @ciudadAux = REPLACE(@ciudadAux,'ú','u');

		SET @codigoPostalAux = NULL;
		EXEC Direccion.obtenerCodigoPostal @ciudadAux,@codigoPostalAux OUTPUT;

		update #TablaDireccionAux
			SET codigoPostal = COALESCE(@codigoPostalAux,'-')
			where legajo = @cursorAux;

		SET @i = @i + 1;
		SET @cursorAux = (SELECT legajo FROM 
						(SELECT Legajo,ROW_NUMBER() OVER(ORDER BY legajo) as rowNum
						FROM #TablaDireccionAux) as x WHERE rowNum = @i);
	END

	INSERT INTO Sucursal.Cargo
		SELECT DISTINCT Cargo FROM #tablaAux
	INSERT INTO Sucursal.Turno
		SELECT DISTINCT Turno FROM #tablaAux



	SELECT * FROM #TablaDireccionAux
	SELECT * FROM #tablaAux
	DROP TABLE #tablaAux;
	DROP TABLE #TablaDireccionAux;
END;
GO
EXEC Empleado.ArchComplementario_importarEmpleado 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx';
GO
*/
/*
	DECLARE @cursorAux INT,
			@i INT = 1;
	SET @SqlDinamico = '';
	SET @cursorAux = CAST((SELECT TOP(1) legajo FROM #TablaDireccionAux ORDER BY legajo) AS int);
	DECLARE @cuilAux VARCHAR(13);
	DECLARE @codigoPostalAux VARCHAR(10);
	DECLARE @sexoAux CHAR;
	DECLARE @dniAux VARCHAR(8);
	DECLARE @ciudadAux VARCHAR(MAX)
	WHILE @cursorAux IS NOT NULL
	BEGIN
		SELECT @sexoAux = Sexo,@dniAux = DNI FROM #tablaAux WHERE @cursorAux = legajo;
		EXEC @cuilAux = Empleado.calcularCUIL @dniAux,@sexoAux;
		update #tablaAux
			SET CUIL = @cuilAux
			WHERE legajo = @cursorAux;
		SET @ciudadAux = (SELECT localidad FROM #TablaDireccionAux WHERE legajo = @cursorAux);
		EXEC Direccion.obtenerCodigoPostal @ciudadAux,@codigoPostalAux OUTPUT;

		update #TablaDireccionAux
			SET codigoPostal = @codigoPostalAux
			where legajo = @cursorAux;

		SET @i = @i + 1;
		SET @SqlDinamico = 'SET @cursorAux = CAST((SELECT TOP('+ @i +') legajo FROM #TablaDireccionAux ORDER BY legajo) AS int)';
		EXECUTE sp_executesql @SqlDinamico;
	END*/

--		DROP PROCEDURE Producto.importarCatalogoCSV
GO
--EXEC Producto.importarCatalogoCSV 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Productos\catalogo.csv'
GO
CREATE OR ALTER PROCEDURE Producto.importarCatalogoCSV (@rutaArchivo NVARCHAR(MAX))
AS BEGIN
	DECLARE @i INT = 1,
			@ultFila INT;
	DECLARE @valorDelDolar DECIMAL(6,2);
	DECLARE @SqlDinamico NVARCHAR(MAX);
	CREATE TABLE #Catalogo
	(
		id INT identity(1,1),
		Categoria VARCHAR(255),
		Nombre VARCHAR(255),
		Precio DECIMAL(10,2),
		PrecioReferencia DECIMAL(10,2),
		UnidadReferencia VARCHAR(255)
	);
	CREATE TABLE #aux
	(
		campo VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS
	)
	CREATE TABLE #campoConComillas
	(
		fila INT IDENTITY(1,1),
		parteUno VARCHAR(MAX),
		parteDos VARCHAR(MAX),
		parteTres VARCHAR(MAX)
	)
	CREATE TABLE #campoSinComillas
	(
		fila INT IDENTITY(1,1),
		campo VARCHAR(MAX)
	)

	SET @SqlDinamico = 'BULK INSERT #aux
					FROM '''+ @rutaArchivo +'''
					WITH
					(
						FIELDTERMINATOR = '','',
						ROWTERMINATOR = ''0x0A'',
						CODEPAGE=''65001'',
						FIRSTROW = 2
					);';
	EXEC sp_executesql @SqlDinamico;

	INSERT #campoConComillas (parteDos,parteUno,parteTres)
			SELECT SUBSTRING(campo, CHARINDEX('"',campo,1) + 1, CHARINDEX('"',SUBSTRING(campo,CHARINDEX('"',campo,1) + 1,LEN(campo)),1) - 1) AS parteDos,
				LEFT(campo,CHARINDEX(SUBSTRING(campo, CHARINDEX('"',campo,1) + 1, CHARINDEX('"',SUBSTRING(campo,CHARINDEX('"',campo,1) + 1,LEN(campo)),1) - 1),campo,1) - 3) AS parteUno,
				SUBSTRING(campo, CHARINDEX('",',campo,1) + 2,LEN(campo))  AS parteTres
				FROM #aux
				WHERE CHARINDEX('"',campo,1) > 0;

	SET @ultFila = (SELECT TOP(1) fila FROM #campoConComillas ORDER BY fila DESC);
	DECLARE @categoria NVARCHAR(MAX),
			@nombreProducto NVARCHAR(MAX),
			@precio NVARCHAR(MAX),
			@precioReferencia NVARCHAR(MAX),
			@unidadReferencia NVARCHAR(MAX),
			@parteUno NVARCHAR(MAX),
			@parteDos NVARCHAR(MAX),
			@parteTres NVARCHAR(MAX);

	WHILE (@i <= @ultFila)
	BEGIN
		SELECT @parteUno = parteUno, @parteDos = parteDos, @parteTres = parteTres 
			FROM #campoConComillas WHERE fila = @i;

		SET @categoria = SUBSTRING(@parteUno,CHARINDEX(',',@parteUno,1) + 1,LEN(@parteUno));
		SET @nombreProducto = @parteDos;

		SET @precio = SUBSTRING(@parteTres,1,CHARINDEX(',',@parteTres,1) - 1);

		SET @parteTres = SUBSTRING(@parteTres,CHARINDEX(',',@parteTres,1) + 1,LEN(@parteTres));

		SET @precioReferencia = SUBSTRING(@parteTres,1,CHARINDEX(',',@parteTres,1) - 1);

		SET @parteTres = SUBSTRING(@parteTres,CHARINDEX(',',@parteTres,1) + 1,LEN(@parteTres));

		SET @unidadReferencia = SUBSTRING(@parteTres,1,CHARINDEX(',',@parteTres,1) - 1);

		INSERT INTO #Catalogo (Categoria,Nombre,Precio,PrecioReferencia,UnidadReferencia)
			VALUES(LTRIM(RTRIM(@categoria)),LTRIM(RTRIM(@nombreProducto)),CAST(@precio AS decimal(10,2)),CAST(@precioReferencia AS decimal(10,2)),@unidadReferencia);

		SET @i = @i + 1;
	END

	INSERT INTO #campoSinComillas (campo)
		SELECT campo FROM #aux WHERE CHARINDEX('"',campo,1) = 0;

	SET @i = 1;
	SET @ultFila = (SELECT TOP(1) fila FROM #campoSinComillas ORDER BY fila DESC)
	DECLARE @campoParsear VARCHAR(MAX);
	WHILE (@i <= @ultFila)
	BEGIN
		SET @campoParsear = (SELECT campo FROM #campoSinComillas WHERE fila = @i);
		--Categoria
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @categoria = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);
		--Producto
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @nombreProducto = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);
		--Precio
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @precio = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);
		--Precio Referencia
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @precioReferencia = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);
		--Unidad Referencia
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @unidadReferencia = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);

		INSERT INTO #Catalogo (Categoria,Nombre,Precio,PrecioReferencia,UnidadReferencia)
			VALUES (LTRIM(RTRIM(@categoria)),LTRIM(RTRIM(@nombreProducto)),CAST(@precio AS decimal(10,2)),CAST(@precioReferencia AS decimal(10,2)),@unidadReferencia);

		SET @i = @i + 1;
	END;

	WITH RepetidosCTE AS
	(
		SELECT *, ROW_NUMBER() OVER(PARTITION BY Nombre ORDER BY id DESC) AS repetidos FROM #Catalogo
	)
	DELETE FROM RepetidosCTE WHERE repetidos > 1

	EXEC Producto.pasajeDolarAPesos @valorDelDolar OUTPUT;

	INSERT INTO Producto.TipoDeProducto (nombreTipoDeProducto)
		SELECT DISTINCT Categoria FROM #Catalogo;

	SET @i = 1;
	SET @ultFila = (SELECT TOP(1) filas FROM (SELECT ROW_NUMBER() OVER (ORDER BY id) AS filas FROM #Catalogo) AS T ORDER BY filas DESC);
	WHILE (@i <= @ultFila)
	BEGIN
		SELECT @categoria = Categoria,@nombreProducto = Nombre, @precio = Precio, @precioReferencia = PrecioReferencia, @unidadReferencia = UnidadReferencia 
			FROM 
				(
					SELECT Categoria,Nombre,Precio,PrecioReferencia,UnidadReferencia,ROW_NUMBER() OVER (ORDER BY id) AS filas FROM #Catalogo
				) AS T 
			WHERE filas = @i;

		EXEC Producto.agregarProductoConNombreTipoProd @categoria,@nombreProducto,@precio,@precioReferencia,@unidadReferencia

		SET @i = @i + 1;
	END

	DROP TABLE #campoSinComillas;
	DROP TABLE #campoConComillas;
	DROP TABLE #aux;
	DROP TABLE #Catalogo;
END;
GO
EXEC Producto.importarCatalogoCSV 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Productos\catalogo.csv'
GO
