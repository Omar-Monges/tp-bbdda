------------------------------------------------Creacion DB------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'G2900G19')
	CREATE DATABASE G2900G19;
--USE master;
--IF EXISTS (SELECT * FROM sys.databases WHERE name = 'G2900G19') DROP DATABASE G2900G19;
GO
USE G2900G19;
GO
------------------------------------------------Esquemas------------------------------------------------
--Esquema Domicilio
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Direccion')
	EXEC('CREATE SCHEMA Direccion');
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
--Esquema Sucursal
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Sucursal')
	EXEC('CREATE SCHEMA Sucursal');
GO
------------------------------------------------Tablas------------------------------------------------
---Esquema Direccion:
--		Tabla Direccion:
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Direccion')
BEGIN
	CREATE TABLE Direccion.Direccion
	(
		IDDireccion INT IDENTITY(1,1),
		Calle VARCHAR(255) NOT NULL,
		Numero SMALLINT NOT NULL,--short en C
		Piso TINYINT NULL, --unsigned char en C
		Departamento TINYINT NULL,
		CodPostal INT NOT NULL,
		Localidad VARCHAR(255) NOT NULL,
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
		IDSucursal INT IDENTITY(1,1),
		Telefono VARCHAR(9) CHECK(Telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
		IDDireccion INT,
		CONSTRAINT PK_Sucursal PRIMARY KEY(IDSucursal),
		CONSTRAINT FK_Sucursal_Direccion FOREIGN KEY(IDDireccion) REFERENCES Direccion.Direccion(IDDireccion)
	)
END;
GO
--		Tabla Horarios de las sucursales
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Horario')
BEGIN
	CREATE TABLE Sucursal.Horario
	(
		IDHorario INT IDENTITY(1,1),
		IDSucursal INT,
		Dia VARCHAR(10) CHECK(Dia IN ('Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo')),
		Apertura TIME(0) NOT NULL,
		Cierre TIME(0) NOT NULL,
		CONSTRAINT FK_Horario_Sucursal FOREIGN KEY(IDSucursal) REFERENCES Sucursal.Sucursal(IDSucursal),
		CONSTRAINT PK_Horario PRIMARY KEY(IDHorario,IDSucursal)
	)
END;
GO
--		Tabla Turnos de los Empleados
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Turno')
BEGIN
	CREATE TABLE Sucursal.Turno
	(
		IDTurno INT IDENTITY(1,1),
		Descripcion VARCHAR(50) NOT NULL,
		CONSTRAINT PK_Turno PRIMARY KEY(IDTurno)
	)
END;
GO
--		Tabla Cargo de los Empleados
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Cargo')
BEGIN
	CREATE TABLE Sucursal.Cargo
	(
		IDCargo INT IDENTITY(1,1),
		Descripcion VARCHAR(50) NOT NULL,
		CONSTRAINT PK_Cargo PRIMARY KEY(IDCargo)
	)
END;
GO
--Esquema Empleado:
--		Tabla Empleado
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Empleado')
BEGIN
	CREATE TABLE Empleado.Empleado
	(
		Legajo INT IDENTITY(257020,1),
		DNI VARCHAR(8) CHECK(DNI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
		CUIL VARCHAR(13) CHECK(CUIL LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'),
		Nombre VARCHAR(50) NOT NULL,
		Apellido VARCHAR(50) NOT NULL,
		EmailPersonal VARCHAR(50) CHECK(EmailPersonal LIKE '%@%.com'),
		EmailEmpresa VARCHAR(50) CHECK(EmailEmpresa LIKE '@super.com'),
		IDDireccion INT,
		IDSucursal INT,
		IDTurno INT,
		IDCargo INT,
		CONSTRAINT PK_Legajo PRIMARY KEY(Legajo),
		CONSTRAINT FK_Empleado_Direccion FOREIGN KEY(IDDireccion) REFERENCES Direccion.Direccion(IDDireccion),
		CONSTRAINT FK_Empleado_Sucursal FOREIGN KEY(IDSucursal) REFERENCES Sucursal.Sucursal(IDSucursal),
		CONSTRAINT FK_Empleado_Turno FOREIGN KEY(IDTurno) REFERENCES Sucursal.Turno(IDTurno),
		CONSTRAINT FK_Empleado_Cargo FOREIGN KEY(IDCargo) REFERENCES Sucursal.Cargo(IDCargo)
	)
END;
GO
--Esquema Producto:
--		Tabla Linea de Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TipoDeProducto')
BEGIN
	CREATE TABLE Producto.TipoDeProducto
	(
		IDTipoDeProd INT IDENTITY(1,1),
		Descripcion VARCHAR(255),
		CONSTRAINT PK_TipoDeProducto PRIMARY KEY(IDTipoDeProd)
	)
END;
GO
--		Tabla Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Producto')
BEGIN
	CREATE TABLE Producto.Producto
	(
		IDProducto INT IDENTITY(1,1),
		IDTipoDeProd INT,
		Descripcion VARCHAR(255),
		PrecioUnitario DECIMAL(10,2),
		PrecioReferencia DECIMAL(10,2),
		UnidadReferencia VARCHAR(10),
		CONSTRAINT PK_Producto PRIMARY KEY(IDProducto),
		CONSTRAINT FK_Producto_TipoDeProducto FOREIGN KEY(IDTipoDeProd) REFERENCES Producto.TipoDeProducto(IDTipoDeProd)
	)
END;
GO
--Esquema Factura:
--		Tabla Medio De Pago de la Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MedioDePago')
BEGIN
	CREATE TABLE Factura.MedioDePago
	(
		IDMedioDePago INT IDENTITY(1,1),
		Descripcion VARCHAR(50),
		CONSTRAINT PK_MedioDePago PRIMARY KEY(IDMedioDePago)
	);
END;
GO
--		Tabla Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Factura')
BEGIN
	CREATE TABLE Factura.Factura
	(
		IDFactura VARCHAR(11) CHECK(IDFactura LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]'),
		TipoFactura CHAR CHECK(TipoFactura IN ('A', 'B', 'C')),
		TipoCliente VARCHAR(10) CHECK(TipoCliente IN('Normal', 'Member')),
		Genero VARCHAR(10) CHECK(Genero IN('Male', 'Female')),
		FechaHora SMALLDATETIME NOT NULL,
		IDSucursal INT,
		IDMedioDepago INT,
		LegajoEmpleado INT,
		IdentificadorDePago VARCHAR(22) NULL,
		CONSTRAINT PK_Factura PRIMARY KEY(IDFactura),
		CONSTRAINT FK_Factura_Sucursal FOREIGN KEY(IDSucursal) REFERENCES Sucursal.Sucursal(IDSucursal),
		CONSTRAINT FK_Factura_MedioDePago FOREIGN KEY(IDMedioDePago) REFERENCES Factura.MedioDePago(IDMedioDePago),
		CONSTRAINT FK_Factura_LegajoEmpleado FOREIGN KEY(LegajoEmpleado) REFERENCES Empleado.Empleado(Legajo)
	)
END;
GO
--		Tabla Detalle De Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DetalleFactura')
BEGIN
	CREATE TABLE Factura.DetalleFactura
	(
		IDFactura VARCHAR(11),
		IDDetalleFactura INT,
		IDProducto INT,
		Cantidad SMALLINT NOT NULL,
		CONSTRAINT PK_DetalleFactura PRIMARY KEY(IDFactura,IDDetalleFactura),
		CONSTRAINT FK_DetalleFactura_Producto FOREIGN KEY(IDProducto) REFERENCES Producto.Producto(IDProducto),
		CONSTRAINT FK_DetalleFactura_Factura FOREIGN KEY(IDFactura) REFERENCES Factura.Factura(IDFactura),
	)
END;
GO