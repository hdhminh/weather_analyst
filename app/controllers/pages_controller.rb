class PagesController < ApplicationController
  # Ensure users are authenticated before they can access any actions in this controller.
  before_action :authenticate_user!

  # The main action for displaying weather information.
  def index
    if params[:city]
      # Fetch weather data for the requested city.
      weather_data = get_weather_data(params[:city])
  
      if weather_data[:error]
        # If there is an error in fetching data, display the error message.
        @error_message = weather_data[:error]
        @weather_data_present = false
      else
        # If no error, prepare weather data for display.
        @error_message = nil
        @is_celsius = true  # Assuming temperatures are in Celsius.
        @city_name = params[:city]

        # Extract specific current weather details.
        @temperature = weather_data[:current_weather][:temperature]
        @humidity = weather_data[:current_weather][:humidity]
        @wind_speed = weather_data[:current_weather][:wind_speed]
        @description = weather_data[:current_weather][:description]

        # Fetch forecast data.
        @forecast = weather_data[:forecast]
        @weather_data_present = true
      end
    else
      # Default values when no city is specified.
      @city_name = ""
      @temperature = "N/A"
      @humidity = nil
      @wind_speed = nil
      @description = "N/A"
      @error_message = nil
      @weather_data_present = false
    end
  end

  private

  # Fetch weather data for a specific city by combining geolocation, current weather, and forecast APIs.
  def get_weather_data(city)
    api_key = ENV['OPENWEATHER_API_KEY']  # Load API key from environment variables.

    # Fetch geolocation (latitude and longitude) for the city.
    geo_data = get_geolocation(city, api_key)
    return { error: "Oops! Please try another city." } if geo_data[:error]

    latitude = geo_data[:latitude]
    longitude = geo_data[:longitude]

    # Fetch current weather data based on latitude and longitude.
    current_weather = get_current_weather(latitude, longitude, api_key)
    return { error: "Unable to retrieve weather data. Please try again later." } if current_weather[:error]

    # Fetch 5-day forecast data.
    forecast = get_forecast(latitude, longitude, api_key)

    { current_weather: current_weather, forecast: forecast }
  end

  # Fetch geolocation (latitude and longitude) using the OpenWeather Geocoding API.
  def get_geolocation(city, api_key)
    geo_url = "http://api.openweathermap.org/geo/1.0/direct?q=#{city}&limit=1&appid=#{api_key}"
    geo_response = Net::HTTP.get(URI(geo_url))
    geo_data = JSON.parse(geo_response)

    # Handle cases where no valid geolocation data is returned.
    if geo_data.nil? || geo_data.empty? || !geo_data[0].key?("lat") || !geo_data[0].key?("lon")
      return { error: true }
    end

    { latitude: geo_data[0]["lat"], longitude: geo_data[0]["lon"] }
  end

  # Fetch current weather details using latitude and longitude.
  def get_current_weather(latitude, longitude, api_key)
    weather_url = "http://api.openweathermap.org/data/2.5/weather?lat=#{latitude}&lon=#{longitude}&units=metric&appid=#{api_key}"
    response = Net::HTTP.get(URI(weather_url))
    weather_data = JSON.parse(response)

    # Handle errors returned by the API.
    if weather_data["cod"] != 200
      return { error: true }
    end
    
    # Extract and return key weather attributes.
    {
      temperature: weather_data["main"]["temp"],
      humidity: weather_data["main"]["humidity"],
      wind_speed: weather_data["wind"]["speed"],
      description: weather_data["weather"][0]["description"],
    }
  end

  # Fetch 5-day forecast data for a city using its geolocation.
  def get_forecast(latitude, longitude, api_key)
    forecast_url = "http://api.openweathermap.org/data/2.5/forecast?lat=#{latitude}&lon=#{longitude}&appid=#{api_key}&units=metric"
    response = Net::HTTP.get(URI(forecast_url))
    
    begin
      data = JSON.parse(response)
    rescue JSON::ParserError
      # Handle invalid API response formats.
      return { error: true, message: "Invalid response from API" }
    end
  
    # Handle API errors.
    return { error: true, message: data["message"] || "API returned an error" } unless data["cod"] == "200" && data["list"]
  
    # Extract sunrise and sunset times.
    sunrise_time = format_time(data.dig("city", "sunrise"))
    sunset_time = format_time(data.dig("city", "sunset"))
  
    # Organize forecast data into daily summaries.
    data["list"].each_slice(8).map do |day_data|
      process_day_data(day_data, sunrise_time, sunset_time)
    end.compact
  end
  
  # Process weather data for a single day.
  def process_day_data(day_data, sunrise_time, sunset_time)
    return nil if day_data.nil? || day_data.empty?
  
    first_data = day_data[0]
    return nil unless first_data
  
    # Calculate min/max temperature, average humidity, pressure, and rain probability.
    temp_min = day_data.map { |d| d.dig("main", "temp_min") }.compact.min
    temp_max = day_data.map { |d| d.dig("main", "temp_max") }.compact.max
    humidity = day_data.map { |d| d.dig("main", "humidity") }.compact
    pressure = day_data.map { |d| d.dig("main", "pressure") }.compact
    pop = day_data.map { |d| d["pop"] }.compact
    avg_humidity = humidity.any? ? (humidity.sum / humidity.size) : "N/A"
    avg_pressure = pressure.any? ? (pressure.sum / pressure.size) : "N/A"
    avg_pop = pop.any? ? (pop.sum / pop.size * 100).round(1) : "N/A"
  
    # Return processed data for a single day.
    {
      date: Time.at(first_data["dt"]).strftime("%a, %d %b"),
      temp_min: temp_min || "N/A",
      temp_max: temp_max || "N/A",
      weather_description: first_data.dig("weather", 0, "description") || "N/A",
      humidity: avg_humidity,
      pressure: avg_pressure,
      rain_probability: avg_pop,
      wind_speed: first_data.dig("wind", "speed") || "N/A",
      sunrise: sunrise_time,
      sunset: sunset_time,
      icon_url: get_icon_for_day(first_data)
    }
  end
  
  # Format a UNIX timestamp into a human-readable time format.
  def format_time(unix_time)
    unix_time ? Time.at(unix_time).strftime("%H:%M") : "N/A"
  end  

  # Generate an icon URL for the weather condition of a day.
  def get_icon_for_day(weather_data)
    icon_code = weather_data.dig("weather", 0, "icon")
    "https://openweathermap.org/img/wn/#{icon_code}@4x.png"
  end
end
