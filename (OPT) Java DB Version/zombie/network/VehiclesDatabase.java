package zombie.network;

import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaTableIterator;
import zombie.ZomboidFileSystem;
import zombie.core.Translator;
import zombie.vehicles.BaseVehicle;
import zombie.vehicles.VehicleManager;

import java.sql.*;
import java.util.ArrayList;

public class VehiclesDatabase {
    private static VehiclesDatabase instance;
    private Connection conn;

    // Private constructor to implement the Singleton pattern
    private VehiclesDatabase() {
        // No persistent connection here
    }

    // Method to get the singleton instance
    public static VehiclesDatabase getInstance() throws SQLException {
        if (instance == null) {
            instance = new VehiclesDatabase();
        }
        return instance;
    }

    // Method to close the connection if needed in future contexts.
    public void close() throws SQLException {
        if (this.conn != null && !this.conn.isClosed()) {
            this.conn.close();
            this.conn = null;
        }
    }

    public ArrayList<DBResult> getTableResult() throws SQLException {
        ArrayList<DBResult> results = new ArrayList<>();
        String sqlQuery = "SELECT id, x, y FROM vehicles";
        String dbPath = ZomboidFileSystem.instance.getCurrentSaveDir() + "/vehicles.db";
        String url = "jdbc:sqlite:" + dbPath;

        try (Connection conn = DriverManager.getConnection(url);
             PreparedStatement preparedStatement = conn.prepareStatement(sqlQuery);
             ResultSet resultSet = preparedStatement.executeQuery()) {

            // Definition of columns to include (for now just id, x and y, z is useless for vehicles, is always 0.)
            ArrayList<String> columns = new ArrayList<>();
            columns.add("id_vehicle"); // can't name it just "id" because LUA side we don't display column with name "id"
            columns.add("x");
            columns.add("y");
            columns.add("script_name");
            columns.add("real_name");

            // Creation of DBResult for each row
            while (resultSet.next()) {
                DBResult dbResult = new DBResult();
                dbResult.setColumns(columns);
                dbResult.setTableName("vehicles");

                // Population of column values
                dbResult.getValues().put("id_vehicle", resultSet.getString("id"));
                dbResult.getValues().put("x", resultSet.getString("x"));
                dbResult.getValues().put("y", resultSet.getString("y"));

                // Popolazione dei valori delle colonne
                String idString = resultSet.getString("id");
                dbResult.getValues().put("id_vehicle", idString);
                dbResult.getValues().put("x", resultSet.getString("x"));
                dbResult.getValues().put("y", resultSet.getString("y"));

                // Inizializza script_name e real_name come "Unknown"
                dbResult.getValues().put("script_name", "Unknown");
                dbResult.getValues().put("real_name", "Unknown");

                // Tentativo di conversione dell'ID in short e ricerca del veicolo
                try {
                    short vehicleId = Short.parseShort(idString);
                    BaseVehicle tempVehicle = VehicleManager.instance.getVehicleByID(vehicleId);
                    if (tempVehicle != null) {
                        String script_name = tempVehicle.getScriptName();
                        String real_name = Translator.getText("IGUI_VehicleName" + tempVehicle.getScript().getName());
                        dbResult.getValues().put("script_name", script_name);
                        dbResult.getValues().put("real_name", real_name);
                    } else {
                        System.out.println("Veicolo non trovato per ID: " + vehicleId);
                        // script_name e real_name rimangono "Unknown"
                    }
                } catch (NumberFormatException ex) {
                    System.err.println("ID non valido o fuori dall'intervallo short: " + idString);
                    ex.printStackTrace();
                    // script_name e real_name rimangono "Unknown"
                }

                // Aggiunta del DBResult alla lista dei risultati
                results.add(dbResult);
            }

        } catch (SQLException e) {
            e.printStackTrace();
            throw e; // Rilancia l'eccezione per essere gestita dal chiamante
        }

        return results;
    }
}
