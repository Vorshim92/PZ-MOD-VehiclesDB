package zombie.network;

import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaTableIterator;
import zombie.ZomboidFileSystem;

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

            // Creation of DBResult for each row
            while (resultSet.next()) {
                DBResult dbResult = new DBResult();
                dbResult.setColumns(columns);
                dbResult.setTableName("vehicles");

                // Population of column values
                dbResult.getValues().put("id_vehicle", resultSet.getString("id"));
                dbResult.getValues().put("x", resultSet.getString("x"));
                dbResult.getValues().put("y", resultSet.getString("y"));

                // Adding the DBResult to the list
                results.add(dbResult);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return results;
    }
}
