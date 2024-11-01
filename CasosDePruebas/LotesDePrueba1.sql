


EXEC Sucursal.agregarCargo 'Cargo2'

DECLARE @var VARCHAR(255) = NULL
EXEC Sucursal.agregarCargo @var

EXEC Sucursal.modificarCargo 3,NULL

EXEC Sucursal.eliminarCargo 4
SELECT * FROM Sucursal.Cargo
-------------------------------------------
EXEC Sucursal.agregarTurno 'Noche' --2

EXEC Sucursal.modificarTurno 2,'Dia'

EXEC Sucursal.eliminarTurno 2

SELECT * FROM Sucursal.Turno

-------------------------------------------