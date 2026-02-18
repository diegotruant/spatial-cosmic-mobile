  Widget _buildChartWithControls() {
    final profileService = context.watch<src_profile.AthleteProfileService>();
    final settings = context.watch<SettingsService>();
    // final workoutService = context.watch<WorkoutService>(); // REMOVED to prevent rebuilds

    return Stack(
      children: [
        LiveWorkoutChart(
          isZoomed: _isChartZoomed, 
          showPowerZones: settings.showPowerZones,
          wPrime: profileService.wPrime,
          cp: profileService.ftp?.toInt() ?? 250,
        ),
        Positioned(
          top: 8,
          right: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isChartZoomed = !_isChartZoomed),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Icon(
                  _isChartZoomed ? LucideIcons.minimize2 : LucideIcons.maximize2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
