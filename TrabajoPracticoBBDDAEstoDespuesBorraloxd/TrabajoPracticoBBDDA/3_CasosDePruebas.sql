USE Com2900G19
GO

SELECT * FROM Factura.Factura
SELECT * FROM Producto.Producto
SELECT * FROM Factura.verFacturaDetallada
-- use master
/*
SELECT * FROM Empleado.Empleado
SELECT * FROM Direccion.Direccion
SELECT * FROM Sucursal.Sucursal
SELECT * FROM Sucursal.Cargo
SELECT * FROM Sucursal.Turno
*/
SELECT * FROM Direccion.Direccion
------------------------------------------------Esquema Dirección------------------------------------------------
/*
Se probará con el procedure Empleado.agregarEmpleado
Formato:
	EXEC Empleado.agregarEmpleado DNI,Nombre,Apellido,Sexo,EmailPersonal,EmailEmpresarial,IDSucursal,IDTurno,IDCargo,
									NombreCalle,NumeroDeCalle,CodigoPostal,Localidad,Provincia,Piso,NumeroDeDepartamento

SELECT * FROM Direccion.Direccion
->1) Agregamos una calle nula:
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',1,2,1,
								NULL,3140,'1333','Rosario','Santa Fé', NULL, NULL			--<--- Salida esperada: Error
->2) Agregamos una calle vacía:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',2,2,1,
								'              ',3140,'1333','Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
->3) Agregamos un numero de calle vacío:	<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',3,2,1,
								'nombreDeCalleXD',3140,'1333','Rosario','Santa Fé', NULL, NULL	--<--- Salida esperada: Error
->4) Agregamos un numero de calle negativo:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',1,2,1,
								'San Martin',-314,'1333','Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
->5) Agregamoso un codigo postal NULO
	EXEC Empleado.agregarEmpleado '12345678','Marcos','zalaC','M','topicos@hotmail.com','deProgramacion@superA.com',1,2,1,
								'EstoEsUnaCalle',3140,NULL,'Laferrere','Santa Fé', NULL, NULL		--<--- Salida esperada: Todo_Ok
->6) Agregamos un código postal vacío
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',1,2,1,
								'San Martin',3140,'       ','Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
->7) Agregamos una localidad NULA (Es lo mismo con Provincia):
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',1,2,1,
								'San Martin',3140,'1333',NULL,'Santa Fé', NULL, NULL		--<--- Salida esperada: Error
->8) Agregamos una localidad vacía (es lo mismo  con Provincia):
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',1,2,1,
								'San Martin',3140,'1333','      ','Santa Fé', NULL, NULL		--<--- Salida esperada: Error

->9) Agregamos un departamento pero un piso NULO (es lo mismo al revés): 
EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',1,2,1,
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
	EXEC Sucursal.agregarTurno 'Esto es un TUrno'		<--- Salida esperada: Todo ok
	EXEC Sucursal.agregarTurno 'Noche'
->3) Agregamos un turno que ya existe (el del item 2):
	EXEC Sucursal.agregarTurno 'esTo ES uN tuRNO'		<--- Salida esperada: 'El turno ya ha ingresado'
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