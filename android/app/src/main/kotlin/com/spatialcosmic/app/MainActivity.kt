package com.spatialcosmic.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.garmin.fit.*
import java.io.File
import java.util.Date
import java.util.Calendar
import java.util.TimeZone
import java.text.SimpleDateFormat
import java.util.Locale
import kotlin.math.roundToInt

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.spatialcosmic.app/fit_generator"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "generateFitFile") {
                try {
                    val data = call.argument<List<Map<String, Any>>>("data") ?: listOf()
                    val rrIntervals = call.argument<List<Map<String, Any>>>("rrIntervals") ?: listOf()
                    val startTimeStr = call.argument<String>("startTime") ?: ""
                    val durationSeconds = call.argument<Int>("duration") ?: 0
                    val totalDistanceFn = call.argument<Double>("totalDistance") ?: 0.0
                    val totalCaloriesFn = call.argument<Double>("totalCalories") ?: 0.0
                    
                    val filePath = generateFitFile(data, rrIntervals, startTimeStr, durationSeconds, totalDistanceFn, totalCaloriesFn)
                    result.success(filePath)
                } catch (e: Exception) {
                    result.error("FIT_GENERATION_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun generateFitFile(
        records: List<Map<String, Any>>,
        rrIntervals: List<Map<String, Any>>,
        startTimeStr: String,
        durationSeconds: Int,
        totalDistance: Double,
        totalCalories: Double
    ): String {
        // Setup Date Parser
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        // Adjust for timezone if needed, but ISO string usually comes as local time from Flutter if DateTime.now() is used.
        // If it sends 'Z' at the end, we need to handle it.
        // Assuming simplistic ISO format without Z for local time or handling it gracefully.
        
        val startDate = if (startTimeStr.isNotEmpty()) {
             // Basic parsing, might need adjustment based on exact Dart format
             // Dart toIso8601String() produces "2023-10-10T14:30:00.000" or similar
             try {
                // Remove fractional seconds if present for SimpleDateFormat ease, or use a robust parser
                val cleanTime = startTimeStr.split(".")[0]
                format.parse(cleanTime)
             } catch (e: Exception) {
                Date()
             }
        } else {
            Date()
        } ?: Date()

        val fitStartTime = DateTime(startDate)

        // Create Output File
        val fileName = "activity_${System.currentTimeMillis()}.fit"
        val outputDir = context.getExternalFilesDir(null) // App-specific external storage
        val outputFile = File(outputDir, fileName)
        
        val encoder = FileEncoder(outputFile, Fit.ProtocolVersion.V2_0)
        
        // Write FileIdMesg
        val fileIdMesg = FileIdMesg()
        fileIdMesg.type = com.garmin.fit.File.ACTIVITY
        fileIdMesg.manufacturer = Manufacturer.DEVELOPMENT
        fileIdMesg.product = 123
        fileIdMesg.serialNumber = 12345L
        fileIdMesg.timeCreated = fitStartTime
        encoder.write(fileIdMesg)
        
        // Write Developer Data Field Definitions if needed (skipping for now until explicitly requested)
        
        // Write SessionMesg (Start) - Optional but good practice to verify definition? 
        // Actually, usually we write messages in chronological order. 
        // FileId -> DeveloperFields -> Records -> Lap -> Session -> Activity
        
        // We iterate records and write them
        var maxHr = 0
        var totalPower = 0.0
        var powerCount = 0
        
        for (recMap in records) {
            val timestampStr = recMap["timestamp"] as? String ?: ""
            val rDate = try {
                 val cleanTime = timestampStr.split(".")[0]
                 format.parse(cleanTime)
            } catch (e: Exception) { Date() } ?: Date()
            
            val record = RecordMesg()
            record.timestamp = DateTime(rDate)
            
            val distance = (recMap["distance"] as? Number)?.toFloat() ?: 0f
            val speed = (recMap["speed"] as? Number)?.toFloat() ?: 0f
            val power = (recMap["power"] as? Number)?.toInt()
            val hr = (recMap["hr"] as? Number)?.toShort()
            val cadence = (recMap["cadence"] as? Number)?.toShort()

            if (distance > 0) record.distance = distance // meters
            if (speed > 0) record.enhancedSpeed = speed // m/s
            if (power != null) {
                record.power = power
                totalPower += power
                powerCount++
            }
            if (hr != null) {
                record.heartRate = hr.toShort()
                if (hr > maxHr) maxHr = hr.toInt()
            }
            if (cadence != null) record.cadence = cadence.toShort()
            
            encoder.write(record)
        }
        
        // Add HRV Data if present
        // Convert input structure: List<Map<String, dynamic>> where 'rr' is List<int> (integers)
        // FIT `hrv` message message expects arrays of times in seconds.
        for (rrMap in rrIntervals) {
             val rrList = rrMap["rr"] as? List<Int>
             if (rrList != null && rrList.isNotEmpty()) {
                 val hrvMesg = HrvMesg()
                 for (i in rrList.indices) {
                     // Input is typically ms (e.g. 800), FIT expects seconds (e.g. 0.8)
                     hrvMesg.setTime(i, rrList[i] / 1000.0f)
                 }
                 encoder.write(hrvMesg)
             }
        }

        // Write LapMesg
        val lapMesg = LapMesg()
        lapMesg.timestamp = DateTime(Date()) // Now
        lapMesg.startTime = fitStartTime
        lapMesg.totalElapsedTime = durationSeconds.toFloat()
        lapMesg.totalTimerTime = durationSeconds.toFloat()
        lapMesg.totalDistance = totalDistance.toFloat()
        lapMesg.totalCalories = totalCalories.toInt()
        val avgPower = if (powerCount > 0) (totalPower / powerCount).toInt() else 0
        lapMesg.avgPower = avgPower
        lapMesg.maxHeartRate = maxHr.toShort()
        // lapMesg.avgHeartRate = ... (calculate if needed)
        
        encoder.write(lapMesg)

        // Write SessionMesg
        val sessionMesg = SessionMesg()
        sessionMesg.timestamp = DateTime(Date())
        sessionMesg.startTime = fitStartTime
        sessionMesg.totalElapsedTime = durationSeconds.toFloat()
        sessionMesg.totalTimerTime = durationSeconds.toFloat()
        sessionMesg.totalDistance = totalDistance.toFloat()
        sessionMesg.totalCalories = totalCalories.toInt()
        sessionMesg.avgPower = avgPower
        sessionMesg.maxHeartRate = maxHr.toShort()
        sessionMesg.sport = Sport.CYCLING
        sessionMesg.subSport = SubSport.INDOOR_CYCLING // CRITICAL FOR STRAVA
        sessionMesg.numLaps = 1
        
        encoder.write(sessionMesg)
        
        // Write ActivityMesg
        val activityMesg = ActivityMesg()
        activityMesg.timestamp = DateTime(Date())
        activityMesg.numSessions = 1
        activityMesg.totalTimerTime = durationSeconds.toFloat()
        
        encoder.write(activityMesg)

        encoder.close()
        
        return outputFile.absolutePath
    }
}
