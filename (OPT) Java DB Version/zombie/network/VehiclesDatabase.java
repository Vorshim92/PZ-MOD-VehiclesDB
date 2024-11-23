package zombie.network;


import zombie.ZomboidFileSystem;
import zombie.core.logger.ExceptionLogger;
import zombie.iso.IsoObject;
import zombie.iso.IsoWorld;
import zombie.util.ByteBufferOutputStream;
import zombie.vehicles.BaseVehicle;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.sql.*;
import java.util.ArrayList;

public class VehiclesDatabase {
    private static VehiclesDatabase instance;

    private VehiclesDatabase() {
        // No persistent connection here
    }

    public static VehiclesDatabase getInstance() {
        if (instance == null) {
            instance = new VehiclesDatabase();
        }
        return instance;
    }

    public ArrayList<DBResult> getTableResult() throws SQLException {
        ArrayList<DBResult> results = new ArrayList<>();
        String sqlQuery = "SELECT id, wx, wy, x, y, data, worldversion FROM vehicles";
        String dbPath = ZomboidFileSystem.instance.getCurrentSaveDir() + "/vehicles.db";
        String url = "jdbc:sqlite:" + dbPath;

        try (Connection conn = DriverManager.getConnection(url);
             PreparedStatement preparedStatement = conn.prepareStatement(sqlQuery);
             ResultSet resultSet = preparedStatement.executeQuery()) {

            // Definition of columns to include
            ArrayList<String> columns = new ArrayList<>();
            columns.add("id_vehicle");
            columns.add("x");
            columns.add("y");
            columns.add("script_name");
            columns.add("real_name");

            while (resultSet.next()) {
                DBResult dbResult = new DBResult();
                dbResult.setColumns(columns);
                dbResult.setTableName("vehicles");

                String idString = resultSet.getString("id");
                dbResult.getValues().put("id_vehicle", idString);
                dbResult.getValues().put("x", resultSet.getString("x"));
                dbResult.getValues().put("y", resultSet.getString("y"));

                // Initialize script_name and real_name as "Unknown"
                dbResult.getValues().put("script_name", "Unknown");
                dbResult.getValues().put("real_name", "Unknown");

                // Create VehicleBuffer and set bytes from InputStream
                VehicleBuffer vehicleBuffer = new VehicleBuffer();
                InputStream dataStream = resultSet.getBinaryStream("data");
                if (dataStream == null) {
                    System.err.println("No data stream for vehicle ID: " + idString);
                    continue;
                }
                vehicleBuffer.setBytes(dataStream);

                // Set other VehicleBuffer fields
                vehicleBuffer.m_id = resultSet.getInt("id");
                vehicleBuffer.m_wx = resultSet.getInt("wx");
                vehicleBuffer.m_wy = resultSet.getInt("wy");
                vehicleBuffer.m_x = resultSet.getFloat("x");
                vehicleBuffer.m_y = resultSet.getFloat("y");
                vehicleBuffer.m_WorldVersion = resultSet.getInt("worldversion");

                // Prepare the data buffer
                ByteBuffer dataBuffer = vehicleBuffer.m_bb;
                dataBuffer.order(ByteOrder.BIG_ENDIAN); // Set byte order if necessary

                // Read active flag and class ID
                boolean active = dataBuffer.get() != 0;
                byte classID = dataBuffer.get();
                if (classID != IsoObject.getFactoryVehicle().getClassID()) {
                    System.err.println("Invalid class ID for vehicle ID: " + idString);
                    continue;
                }
                if (!active) {
                    System.err.println("Vehicle ID: " + idString + " is not active");
                    continue;
                }
                // Do NOT reset the buffer position here

                // Load the vehicle
                BaseVehicle tempVehicle = new BaseVehicle(IsoWorld.instance.CurrentCell);
                try {
                    tempVehicle.load(dataBuffer, vehicleBuffer.m_WorldVersion);

                    String scriptName = tempVehicle.getScriptName();
                    // String realName = tempVehicle.getScript().getName();
                    dbResult.getValues().put("script_name", scriptName);
                    // dbResult.getValues().put("real_name", realName);
                } catch (Exception ex) {
                    System.err.println("Error loading vehicle data for ID: " + idString);
                    ex.printStackTrace();
                    continue; // Skip this vehicle
                }

                results.add(dbResult);
            }

        } catch (SQLException | IOException e) {
            ExceptionLogger.logException(e);
            throw new SQLException("An error occurred while processing vehicle data", e);
        }

        return results;
    }

    // Thread-local variables
    private static final ThreadLocal<ByteBuffer> TL_SliceBuffer = ThreadLocal.withInitial(() -> ByteBuffer.allocate(32768));
    private static final ThreadLocal<byte[]> TL_Bytes = ThreadLocal.withInitial(() -> new byte[1024]);

    public class VehicleBuffer {
        int m_id = -1;
        int m_wx;
        int m_wy;
        float m_x;
        float m_y;
        int m_WorldVersion;
        ByteBuffer m_bb = ByteBuffer.allocate(32768);

        void setBytes(InputStream var1) throws IOException {
            ByteBufferOutputStream var2 = new ByteBufferOutputStream(this.m_bb, true);
            var2.clear();
            byte[] var3 = TL_Bytes.get();

            int var4;
            while ((var4 = var1.read(var3)) != -1) {
                var2.write(var3, 0, var4);
            }

            var2.flip();
            this.m_bb = var2.getWrappedBuffer();
        }
    }
}
