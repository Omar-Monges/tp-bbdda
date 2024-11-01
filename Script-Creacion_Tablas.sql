------------------------------------------------Creacion DB------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'G2900G19')
	CREATE DATABASE G2900G19;
--USE master;
--IF EXISTS (SELECT * FROM sys.databases WHERE name = 'G2900G19') DROP DATABASE G2900G19;
GO
USE G2900G19;
GO
------------------------------------------------Esquemas------------------------------------------------
--Esquema Direccion
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Direccion')
	EXEC('CREATE SCHEMA Direccion');
GO
--Esquema Sucursal
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Sucursal')
	EXEC('CREATE SCHEMA Sucursal');
GO
--Esquema Empleado
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Empleado')
	EXEC('CREATE SCHEMA Empleado');
GO
--Esquema Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Factura')
	EXEC('CREATE SCHEMA Factura');
GO
--Esquema Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Producto')
	EXEC('CREATE SCHEMA Producto');
GO

------------------------------------------------Tablas------------------------------------------------
---Esquema Direccion:
--		Tabla Direccion:
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Direccion')
BEGIN
	CREATE TABLE Direccion.Direccion
	(
		idDireccion INT IDENTITY(1,1),
		calle VARCHAR(255) NOT NULL,
		numeroDeCalle SMALLINT NOT NULL,--short en C
		piso TINYINT NULL, --unsigned char en C
		departamento TINYINT NULL,
		codigoPostal SMALLINT NOT NULL,
		localidad VARCHAR(255) NOT NULL,
		provincia VARCHAR(255) NOT NULL,
		CONSTRAINT PK_DIRECCION PRIMARY KEY(IDDireccion)
	)
END;
GO
--Esquema Sucursal:
--		Tabla Sucursal
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Sucursal')
BEGIN
	CREATE TABLE Sucursal.Sucursal
	(
		idSucursal INT IDENTITY(1,1),
		telefono VARCHAR(9) CHECK(Telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
		idDireccion INT,
		horario VARCHAR(255),
		CONSTRAINT PK_Sucursal PRIMARY KEY(idSucursal),
		CONSTRAINT FK_Sucursal_Direccion FOREIGN KEY(IDDireccion) REFERENCES Direccion.Direccion(idDireccion)
	)
END;
GO
--		Tabla Turnos de los Empleados
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Turno')
BEGIN
	CREATE TABLE Sucursal.Turno
	(
		idTurno INT IDENTITY(1,1),
		nombreTurno VARCHAR(255) NOT NULL,
		CONSTRAINT PK_Turno PRIMARY KEY(idTurno)
	)
END;
GO
--		Tabla Cargo de los Empleados
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Cargo')
BEGIN
	CREATE TABLE Sucursal.Cargo
	(
		idCargo INT IDENTITY(1,1),
		nombreCargo VARCHAR(50) NOT NULL,
		CONSTRAINT PK_Cargo PRIMARY KEY(idCargo)
	)
END;
GO
--Esquema Empleado:
--		Tabla Empleado
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Empleado')
BEGIN
	CREATE TABLE Empleado.Empleado
	(
		legajo INT IDENTITY(1,1),
		dni VARCHAR(8) CHECK(DNI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
		cuil VARCHAR(13) CHECK(CUIL LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'),
		nombre VARCHAR(50) NOT NULL,
		apellido VARCHAR(50) NOT NULL,
		emailPersonal VARCHAR(50) CHECK(EmailPersonal LIKE '%@%.com'),
		emailEmpresarial VARCHAR(50) CHECK(emailEmpresarial LIKE '@aurora.com'),
		idDireccion INT,
		idSucursal INT,
		idTurno INT,
		idCargo INT,
		CONSTRAINT PK_Legajo PRIMARY KEY(legajo),
		CONSTRAINT FK_Empleado_Direccion FOREIGN KEY(idDireccion) REFERENCES Direccion.Direccion(idDireccion),
		CONSTRAINT FK_Empleado_Sucursal FOREIGN KEY(idSucursal) REFERENCES Sucursal.Sucursal(idSucursal),
		CONSTRAINT FK_Empleado_Turno FOREIGN KEY(idTurno) REFERENCES Sucursal.Turno(idTurno),
		CONSTRAINT FK_Empleado_Cargo FOREIGN KEY(idCargo) REFERENCES Sucursal.Cargo(idCargo)
	)
END;
GO
--Esquema Producto:
--		Tabla Linea de Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TipoDeProducto')
BEGIN
	CREATE TABLE Producto.TipoDeProducto
	(
		idTipoDeProducto INT IDENTITY(1,1),
		nombreTipoDeProducto VARCHAR(255),
		CONSTRAINT PK_TipoDeProducto PRIMARY KEY(idTipoDeProducto)
	)
END;
GO
--		Tabla Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Producto')
BEGIN
	CREATE TABLE Producto.Producto
	(
		idProducto INT IDENTITY(1,1),
		idTipoDeProducto INT,
		descripcionProducto VARCHAR(255),
		precioUnitario DECIMAL(10,2),
		precioReferencia DECIMAL(10,2),
		unidadReferencia VARCHAR(255),
		CONSTRAINT PK_Producto PRIMARY KEY(idProducto),
		CONSTRAINT FK_Producto_TipoDeProducto FOREIGN KEY(idTipoDeProducto) REFERENCES Producto.TipoDeProducto(idTipoDeProducto)
	)
END;
GO
--Esquema Factura:
--		Tabla Medio De Pago de la Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MedioDePago')
BEGIN
	CREATE TABLE Factura.MedioDePago
	(
		idMedioDePago INT IDENTITY(1,1),
		nombreMedioDePago VARCHAR(255),
		CONSTRAINT PK_MedioDePago PRIMARY KEY(idMedioDePago)
	);
END;
GO
--		Tabla Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Factura')
BEGIN
	CREATE TABLE Factura.Factura
	(
		idFactura VARCHAR(11) CHECK(idFactura LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]'),
		tipoFactura CHAR CHECK(tipoFactura IN ('A', 'B', 'C')),
		tipoCliente VARCHAR(10) CHECK(tipoCliente IN('Normal', 'Member')),
		genero VARCHAR(10) CHECK(genero IN('Male', 'Female')),
		fechaHora SMALLDATETIME NOT NULL,
		idMedioDepago INT,
		legajoEmpleado INT,
		identificadorDePago VARCHAR(22) NULL,
		CONSTRAINT PK_Factura PRIMARY KEY(idFactura),
		CONSTRAINT FK_Factura_MedioDePago FOREIGN KEY(idMedioDePago) REFERENCES Factura.MedioDePago(idMedioDePago),
		CONSTRAINT FK_Factura_LegajoEmpleado FOREIGN KEY(legajoEmpleado) REFERENCES Empleado.Empleado(legajo)
	)
END;
GO
--		Tabla Detalle De Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DetalleFactura')
BEGIN
	CREATE TABLE Factura.DetalleFactura
	(
		idFactura VARCHAR(11),
		idDetalleFactura INT,
		idProducto INT,
		cantidad SMALLINT NOT NULL,
		CONSTRAINT PK_DetalleFactura PRIMARY KEY(idFactura,idDetalleFactura),
		CONSTRAINT FK_DetalleFactura_Producto FOREIGN KEY(idProducto) REFERENCES Producto.Producto(idProducto),
		CONSTRAINT FK_DetalleFactura_Factura FOREIGN KEY(idFactura) REFERENCES Factura.Factura(idFactura),
	)
END;
GO