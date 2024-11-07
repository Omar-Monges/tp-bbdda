USE Com2900G19
GO
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
--EXEC Factura.archcomplementario_importarMedioDePago 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx';
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

use Com2900G19
-- https://stackoverflow.com/questions/1293330/how-can-i-do-an-update-statement-with-join-in-sql-server
--		DROP PROCEDURE Factura.ArchComplementario_importarEmpleado
CREATE OR ALTER PROCEDURE Factura.ArchComplementario_importarEmpleado (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @tabulador CHAR = CHAR(9);
	DECLARE @espacio CHAR = CHAR(10);

	create table #aux
	(
		fila int identity(1,1),
		legajo varchar(max),
		nombre varchar(max),
		apellido varchar(max),
		dni varchar(max),
		sexo varchar(max),
		direccion varchar(max),
		emailPersonal varchar(max),
		emailEmpresarial varchar(max),
		cuil varchar(max),
		cargo varchar(max),
		sucursal varchar(max),
		turno varchar(max)
	)

	create table #direccionAux
	(
		calle varchar(max),
		numeroDeCalle varchar(max),
		codigoPostal varchar(max),
		localidad varchar(max),
		provincia varchar(max)
	)

	DECLARE @direccionAParsear VARCHAR(MAX),
			@calle VARCHAR(MAX),
			@numeroDeCalle VARCHAR(MAX),
			@codigoPostal VARCHAR(MAX),
			@localidad VARCHAR(MAX),
			@provincia VARCHAR(MAX);
	
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT #aux ';

	SET @SqlDinamico = @SqlDinamico + ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [Empleados$]'')'
	EXECUTE sp_executesql @SqlDinamico;

	DELETE FROM #aux
	WHERE legajo IS NULL

	--SELECT * FROM #aux

	UPDATE #aux
		SET cuil = Empleado.calcularCuil (dni,sexo)
		WHERE cuil IS NULL;

	--DELETE FROM Sucursal.Turno; --Esto borrarlo, es solo pa' q funcione xd
	--SELECT * FROM #aux
	--Agregamos los turnos
	INSERT INTO Sucursal.Turno
		SELECT DISTINCT turno
			FROM #aux a 
			WHERE NOT EXISTS(Select 1 FROM Sucursal.Turno t 
								WHERE t.nombreTurno <> a.turno COLLATE Modern_Spanish_CI_AI);
	UPDATE #aux
		SET turno = t.idTurno
		FROM #aux a JOIN Sucursal.Turno t
			ON a.turno = t.nombreTurno COLLATE Modern_Spanish_CI_AI;
	--Agregamos los cargos
	INSERT INTO Sucursal.Cargo
		SELECT DISTINCT cargo
			FROM #aux a
			WHERE NOT EXISTS(SELECT 1 from Sucursal.Cargo c
								WHERE c.nombreCargo <> a.cargo COLLATE Modern_Spanish_CI_AI);
	UPDATE #aux
		SET cargo = c.idCargo
		FROM #aux a JOIN Sucursal.Cargo c
			ON a.cargo = c.nombreCargo COLLATE Modern_Spanish_CI_AI;
	
	UPDATE #aux
		SET sucursal = s.idSucursal
		FROM (SELECT idSucursal,d.localidad 
				FROM Sucursal.Sucursal s JOIN Direccion.Direccion d 
					ON s.idDireccion = d.idDireccion
			) AS s JOIN #aux a ON s.localidad LIKE a.sucursal COLLATE Modern_Spanish_CI_AI;
	--Arreglamos los espacios en blanco
	UPDATE #aux
		SET emailPersonal = REPLACE(emailPersonal,@tabulador,'_'),
			emailEmpresarial = REPLACE(emailEmpresarial,@tabulador,'_')
	UPDATE #aux
		SET emailPersonal = REPLACE(emailPersonal,@espacio,'_'),
			emailEmpresarial = REPLACE(emailEmpresarial,@espacio,'_')
	--SELECT * FROM Sucursal.Turno
	--SELECT * FROM Sucursal.Cargo

	DECLARE @cursorFila INT = 1,
			@ultFila INT = (SELECT ROW_NUMBER() OVER(ORDER BY legajo) AS filas FROM #aux ORDER BY filas DESC)

	WHILE (@cursorFila <= @ultFila)
	BEGIN
		SET @direccionAParsear = (SELECT * FROM #aux WHERE )
		--Aca lo dejo 7/11 10.38 xd
		SET @cursorFila = @cursorFila + 1;
	END

	SELECT * FROM #aux
	DROP TABLE #aux
END;
GO
EXEC Factura.ArchComplementario_importarEmpleado 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx'
GO
SELECT * FROM Sucursal.Sucursal

SELECT * FROM Sucursal.Cargo
SELECT * FROM Sucursal.Turno

if '.....@.com' LIKE '%@%.com%'
	print 'xd'
else
	print 'XD'
DECLARE @var varchar(max) = 'jorge'
print @var
DECLARE @num int = 2;
SET @var = @num;
print @var


SELECT Num *2 FROM (SELECT 2 AS Num) AS T

SELECT * FROM Sucursal.Turno

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
--		SELECT * FROM Empleado.Empleado
--		DROP PROCEDURE Producto.importarCatalogoCSV
GO
--EXEC Producto.importarCatalogoCSV 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Productos\catalogo.csv'
CREATE OR ALTER PROCEDURE Producto.importarCatalogoCSV (@rutaArchivo NVARCHAR(MAX))
AS BEGIN
	DECLARE @i INT = 1,
			@ultFila INT;
	DECLARE @valorDelDolar DECIMAL(6,2);
	DECLARE @SqlDinamico NVARCHAR(MAX),
			@categoria NVARCHAR(MAX),
			@nombreProducto NVARCHAR(MAX),
			@precio NVARCHAR(MAX),
			@precioReferencia NVARCHAR(MAX),
			@unidadReferencia NVARCHAR(MAX),
			@parteUno NVARCHAR(MAX),
			@parteDos NVARCHAR(MAX),
			@parteTres NVARCHAR(MAX);
	DECLARE @precioDecimalUni DECIMAL(15,2),
			@precioDecimalRef DECIMAL(15,2);

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

	update #Catalogo
		SET Nombre = REPLACE(Nombre,'Ãº','ú')
		WHERE Nombre LIKE '%Ãº%';

	INSERT INTO Producto.TipoDeProducto (nombreTipoDeProducto)
		SELECT DISTINCT Categoria FROM #Catalogo;

	SET @i = 1;
	SET @ultFila = (SELECT TOP(1) filas FROM (SELECT ROW_NUMBER() OVER (ORDER BY id) AS filas FROM #Catalogo) AS T ORDER BY filas DESC);
	WHILE (@i <= @ultFila)
	BEGIN
		SELECT @categoria = Categoria,@nombreProducto = Nombre, @precioDecimalUni = Precio, @precioDecimalRef = PrecioReferencia, @unidadReferencia = UnidadReferencia 
			FROM 
				(
					SELECT Categoria,Nombre,Precio,PrecioReferencia,UnidadReferencia,ROW_NUMBER() OVER (ORDER BY id) AS filas FROM #Catalogo
				) AS T 
			WHERE filas = @i;
		SET @precioDecimalUni = @precioDecimalUni * @valorDelDolar;
		SET @precioDecimalRef = @precioDecimalRef * @valorDelDolar;

		EXEC Producto.agregarProductoConNombreTipoProd @categoria,@nombreProducto,@precioDecimalUni,@precioDecimalRef,@unidadReferencia;

		SET @i = @i + 1;
	END

	DROP TABLE #campoSinComillas;
	DROP TABLE #campoConComillas;
	DROP TABLE #aux;
	DROP TABLE #Catalogo;
END;
GO
--EXEC Producto.importarCatalogoCSV 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Productos\catalogo.csv'
GO
-----------------------------------------
--DROP PROCEDURE Producto.importarProductosElectronicosXLSX
CREATE OR ALTER PROCEDURE Producto.importarProductosElectronicosXLSX (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @idTipoDeProducto INT;
	DECLARE @SqlDinamico NVARCHAR(MAX);
	DECLARE @DolarEnPesos DECIMAL(6,2);

	CREATE TABLE #aux
	(
		nombre VARCHAR(MAX),
		precio DECIMAL(10,2)
	)

	SET @SqlDinamico = 'INSERT #aux';

	SET @SqlDinamico = @SqlDinamico + ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [sheet1$]'')';
	EXECUTE sp_executesql @SqlDinamico;

	EXEC Producto.pasajeDolarAPesos @DolarEnPesos OUTPUT;

	EXEC Producto.agregarTipoDeProducto 'Electronica';
	
	SET @idTipoDeProducto = (SELECT TOP(1) idTipoDeProducto FROM Producto.TipoDeProducto 
								ORDER BY idTipoDeProducto DESC);

	INSERT INTO Producto.Producto (descripcionProducto,idTipoDeProducto,precioUnitario,precioReferencia,unidadReferencia)
		SELECT nombre, @idTipoDeProducto, precio * @DolarEnPesos, precio  * @DolarEnPesos, 'ud' FROM #aux

	DROP TABLE #aux;
END;
--EXEC Producto.importarProductosElectronicosXLSX 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Electronic_accessories.xlsx'
GO
CREATE OR ALTER PROCEDURE Producto.importarProductosImportadosXLSX (@rutaArch VARCHAR(MAX))
AS BEGIN
	
	DECLARE @SqlDinamico NVARCHAR(MAX);

	DECLARE @DolarEnPesos DECIMAL(6,2);

	CREATE TABLE #aux
	(
		nombre VARCHAR(MAX),
		categoria varchar(max),
		precio DECIMAL(10,2),
		precioRef DECIMAL(10,2),
		unidadRef VARCHAR(MAX)
	)

	SET @SqlDinamico = 'INSERT #aux (nombre,categoria,precio)';
	SET @SqlDinamico = @SqlDinamico + ' SELECT NombreProducto,[Categoría],PrecioUnidad
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @rutaArch +'; HDR=YES'', 
														''SELECT * FROM [Listado de Productos$]'')';
	EXECUTE sp_executesql @SqlDinamico;

	INSERT INTO Producto.TipoDeProducto (nombreTipoDeProducto)
		SELECT DISTINCT categoria FROM #aux

	UPDATE #aux
		SET precioRef = precio,
			unidadRef = 'ud'

	EXEC Producto.pasajeDolarAPesos @DolarEnPesos OUTPUT;

	INSERT INTO Producto.Producto (descripcionProducto,precioUnitario,precioReferencia,unidadReferencia,idTipoDeProducto)
		SELECT nombre,precio * @DolarEnPesos,precioRef  * @DolarEnPesos,unidadRef, t.idTipoDeProducto
			FROM #aux a JOIN Producto.TipoDeProducto t
				ON a.categoria like t.nombreTipoDeProducto COLLATE Modern_Spanish_CI_AS;

	DROP TABLE #aux;
END
GO
--EXEC Producto.importarProductosImportadosXLSX 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Productos_importados.xlsx'
GO
-------------------------------------------------
--		DROP PROCEDURE Factura.importarFacturas
CREATE OR ALTER PROCEDURE Factura.importarFacturas (@rutaArch NVARCHAR(MAX))
AS
BEGIN
    DECLARE @SqlDinamico NVARCHAR(MAX);
    
    CREATE TABLE #aux (
        idFactura NVARCHAR(MAX),
        tipoFactura NVARCHAR(MAX),
        ciudad NVARCHAR(MAX),
        tipoCliente NVARCHAR(MAX),
        genero NVARCHAR(MAX),
        producto NVARCHAR(MAX),
        preciounitario NVARCHAR(MAX),
        cantidad NVARCHAR(MAX),
        fecha NVARCHAR(MAX),
        hora NVARCHAR(MAX),
        medioDePago NVARCHAR(MAX),
        empleado NVARCHAR(MAX),
        idDePago NVARCHAR(MAX)
    );
    
    SET @SqlDinamico = N'BULK INSERT #aux
        FROM ''' + @rutaArch + '''
        WITH (
		 DATAFILETYPE = ''widechar'', 
            FIELDTERMINATOR = '';'', 
            CODEPAGE = ''65001'', 
            FIRSTROW = 2
        );';
    EXEC sp_executesql @SqlDinamico;
	
    UPDATE #aux 
		SET producto = REPLACE(producto, 'Ã¡', 'a');		
    UPDATE #aux 
		SET producto = REPLACE(producto, 'Ã©', 'e');
    UPDATE #aux 
		SET producto = REPLACE(producto, 'Ã­', 'i');
    UPDATE #aux 
		SET producto = REPLACE(producto, 'Ã³', 'o');
    UPDATE #aux 
		SET producto = REPLACE(REPLACE(producto, 'ÃƒÂº', 'u'),'Ãº','u');
    UPDATE #aux 
		SET producto = REPLACE(REPLACE(producto, 'Ã±', 'ñ'),'å˜','ñ');
	UPDATE #aux
		SET idDePago = SUBSTRING(idDePago,2,LEN(idDePago))
		WHERE CHARINDEX('-',idDePago,1) = 0;

	UPDATE #aux
		SET ciudad = 'San Justo'
		WHERE ciudad LIKE 'Yangon'
	UPDATE #aux
		SET ciudad = 'Ramos Mejia'
		WHERE ciudad LIKE 'Naypyitaw'
	UPDATE #aux
		SET ciudad = 'Lomas del Mirador'
		WHERE ciudad LIKE 'Mandalay';

	--SELECT * FROM #aux;
	WITH ProductosInexistentesCTE AS
	(
		SELECT * FROM #aux a 
			WHERE NOT EXISTS (
								SELECT 1 FROM Producto.Producto p
									WHERE p.descripcionProducto = a.producto COLLATE Modern_Spanish_CI_AI
							)
	)
	DELETE FROM ProductosInexistentesCTE;
	
	WITH FacturaCTE AS 
	(
		SELECT idFactura AS id,medioDePago,producto,ciudad FROM #aux
	),
	SucursalCTE AS
	(
		SELECT id,medioDePago,producto,d.idSucursal 
			FROM FacturaCTE f JOIN Direccion.verDireccionesDeSucursales d
				ON f.ciudad LIKE d.localidad COLLATE Modern_Spanish_CI_AI
	)
	, NombreProductoCTE (idFactura,medioDePago,idProducto,idSucursal) AS
	(
		SELECT f.id,f.medioDePago,p.idProducto,f.idSucursal 
			FROM SucursalCTE f JOIN Producto.Producto p
				ON f.producto LIKE p.descripcionProducto COLLATE Modern_Spanish_CI_AI
	), NombreMedioDePagoCTE AS
	(
		SELECT p.idFactura,p.idProducto,m.idMedioDePago,p.idSucursal
			FROM NombreProductoCTE p JOIN Factura.MedioDePago m
				ON p.medioDePago LIKE m.nombreMedioDePago COLLATE Modern_Spanish_CI_AI
	),FacturaAInsertarCTE AS
	(
		SELECT  tipoFactura,tipoCliente,genero,CAST(cantidad as smallint) as cantidad,CONVERT(smalldatetime,fecha) + CONVERT(smalldatetime,hora) AS Fecha,n.idProducto,n.idMedioDePago,empleado,idSucursal,idDePago
			FROM NombreMedioDePagoCTE n JOIN (
												SELECT idFactura,tipoFactura,
														tipoCliente,genero,cantidad,fecha,hora,empleado,idDePago FROM #aux
											) AS a
				ON n.idFactura LIKE a.idFactura
	)
	INSERT INTO Factura.Factura (tipoFactura,tipoCliente,genero,cantidad,fechaHora,idProducto,idMedioDepago,legajo,idSucursal,identificadorDePago)
		SELECT * FROM FacturaAInsertarCTE

    DROP TABLE #aux;
END;
GO
--EXEC Factura.agregarFacturas 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Ventas_registradas.csv'
EXEC Producto.importarCatalogoCSV 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Productos\catalogo.csv'
GO
EXEC Producto.importarProductosElectronicosXLSX 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Electronic_accessories.xlsx'
GO
EXEC Producto.importarProductosImportadosXLSX 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Productos_importados.xlsx'
GO
EXEC Factura.archcomplementario_importarMedioDePago 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx';
GO
EXEC Factura.importarFacturas 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Ventas_registradas.csv'
GO
--	SELECT * FROM Factura.Factura