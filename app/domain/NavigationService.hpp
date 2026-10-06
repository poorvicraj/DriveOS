#pragma once

#include "VehicleState.hpp"
#include "SafetyPolicy.hpp"
#include <string>
#include <vector>
#include <functional>
#include <algorithm>
#include <utility>
#include <cmath>
#include <queue>
#include <limits>

namespace driveos::domain {

/**
 * @brief Representation of an intersection/node in the physical road network.
 */
struct RoadNode {
    size_t id{0};
    std::string name;
    double latitude{0.0};
    double longitude{0.0};
};

/**
 * @brief Directed road segment connecting two road nodes with physical road curvature geometry.
 */
struct RoadEdge {
    size_t toNode{0};
    double distanceKm{0.0};
    std::vector<std::pair<double, double>> pathGeometry;
};

/**
 * @brief Result of a Dijkstra Shortest Path calculation.
 */
struct DijkstraResult {
    std::vector<size_t> nodeIds;
    std::vector<std::string> nodeNames;
    std::vector<std::pair<double, double>> waypoints;
    double totalDistanceKm{0.0};
    bool found{false};
};

/**
 * @brief Representation of a real navigation point of interest / destination.
 */
struct NavigationDestination {
    std::string id;
    std::string name;
    std::string category;          // "Landmark", "Favorite", "Work", "Education", "Charging", "Emergency"
    std::string icon;
    float distanceKm{8.4f};
    int etaMinutes{18};
    std::string maneuverText;
    std::string turnIcon;           // "↱", "↰", "↑", "↖", "↗", "↻"
    float destX{0.74f};             // Normalized canvas coordinate fallback
    float destY{0.26f};
    double latitude{12.3052};       // Real Geographic Latitude
    double longitude{76.6552};      // Real Geographic Longitude
    double startLat{12.3551};        // Origin Latitude
    double startLon{76.6186};        // Origin Longitude
    std::string address;
    int speedLimitKmH{60};
    int batteryArrivalSoc{78};
    std::vector<std::pair<double, double>> waypoints;
    size_t startNodeId{0};
    size_t targetNodeId{8};
};

/**
 * @brief Application domain service managing automotive navigation, satellite telemetry,
 * real GPS coordinates, Dijkstra shortest path route computation, and driving simulation.
 */
class NavigationService {
public:
    using NavigationChangedCallback = std::function<void()>;

    explicit NavigationService(SafetyPolicy* safetyPolicy = nullptr)
        : m_safetyPolicy(safetyPolicy)
    {
        initRoadNetwork();
        initDestinations();
    }

    virtual ~NavigationService() = default;

    // --- Destinations & Routing ---
    [[nodiscard]] const std::vector<NavigationDestination>& getDestinations() const noexcept {
        return m_destinations;
    }

    [[nodiscard]] const NavigationDestination& getActiveDestination() const noexcept {
        return m_destinations[m_activeDestinationIndex];
    }

    [[nodiscard]] size_t getActiveDestinationIndex() const noexcept {
        return m_activeDestinationIndex;
    }

    [[nodiscard]] bool isNavigating() const noexcept {
        return m_isNavigating;
    }

    [[nodiscard]] float getRouteProgress() const noexcept {
        return m_routeProgress;
    }

    // --- Moving Vehicle Telemetry along the Road ---
    [[nodiscard]] double getCurrentLatitude() const noexcept {
        return m_currentLat;
    }

    [[nodiscard]] double getCurrentLongitude() const noexcept {
        return m_currentLon;
    }

    [[nodiscard]] double getCurrentHeading() const noexcept {
        return m_currentHeading;
    }

    [[nodiscard]] double getVehicleSpeed() const noexcept {
        return m_vehicleSpeed;
    }

    // --- User's Current Location (Distinct from Moving Vehicle) ---
    [[nodiscard]] double getUserLatitude() const noexcept {
        return m_userLat;
    }

    [[nodiscard]] double getUserLongitude() const noexcept {
        return m_userLon;
    }

    [[nodiscard]] const std::string& getUserLocationTitle() const noexcept {
        return m_userLocationTitle;
    }

    [[nodiscard]] const std::string& getUserLocationAddress() const noexcept {
        return m_userLocationAddress;
    }

    virtual void setUserLocation(double lat, double lon, const std::string& title = "Current Location of the User", const std::string& address = "GSSSIETW Campus, KRS Road, Mysuru") {
        m_userLat = lat;
        m_userLon = lon;
        m_userLocationTitle = title;
        m_userLocationAddress = address;
        notifyObservers();
    }

    // --- Shortest Path & Dijkstra Graph Telemetry ---
    [[nodiscard]] const DijkstraResult& getActiveShortestPath() const noexcept {
        return m_activeShortestPath;
    }

    [[nodiscard]] std::string getPathfindingAlgorithm() const noexcept {
        return "Dijkstra's Shortest Path Algorithm";
    }

    [[nodiscard]] int getShortestPathNodeCount() const noexcept {
        return static_cast<int>(m_activeShortestPath.nodeIds.size());
    }

    [[nodiscard]] double getShortestPathDistanceKm() const noexcept {
        return m_activeShortestPath.totalDistanceKm;
    }

    [[nodiscard]] const std::vector<RoadNode>& getRoadNodes() const noexcept {
        return m_roadNodes;
    }

    /**
     * @brief Computes the shortest road path between any two road nodes using Dijkstra's algorithm.
     */
    DijkstraResult computeDijkstraShortestPath(size_t startNode, size_t targetNode) const {
        if (startNode >= m_roadNodes.size() || targetNode >= m_roadNodes.size()) {
            return {};
        }

        if (startNode == targetNode) {
            DijkstraResult single;
            single.nodeIds = {startNode};
            single.nodeNames = {m_roadNodes[startNode].name};
            single.waypoints = {{m_roadNodes[startNode].latitude, m_roadNodes[startNode].longitude}};
            single.totalDistanceKm = 0.0;
            single.found = true;
            return single;
        }

        const size_t n = m_roadNodes.size();
        std::vector<double> dist(n, std::numeric_limits<double>::infinity());
        std::vector<size_t> prev(n, n);
        std::vector<std::vector<std::pair<double, double>>> prevGeom(n);

        using Element = std::pair<double, size_t>; // (distance, nodeId)
        std::priority_queue<Element, std::vector<Element>, std::greater<Element>> pq;

        dist[startNode] = 0.0;
        pq.push({0.0, startNode});

        while (!pq.empty()) {
            auto [currentDist, u] = pq.top();
            pq.pop();

            if (currentDist > dist[u]) continue;
            if (u == targetNode) break;

            for (const auto& edge : m_roadAdjacency[u]) {
                size_t v = edge.toNode;
                double newDist = dist[u] + edge.distanceKm;
                if (newDist < dist[v]) {
                    dist[v] = newDist;
                    prev[v] = u;
                    prevGeom[v] = edge.pathGeometry;
                    pq.push({newDist, v});
                }
            }
        }

        if (dist[targetNode] == std::numeric_limits<double>::infinity()) {
            return {}; // No path found
        }

        // Reconstruct path nodes from target to start
        std::vector<size_t> pathNodes;
        for (size_t at = targetNode; at != n; at = prev[at]) {
            pathNodes.push_back(at);
            if (at == startNode) break;
        }
        std::reverse(pathNodes.begin(), pathNodes.end());

        DijkstraResult result;
        result.nodeIds = pathNodes;
        result.totalDistanceKm = dist[targetNode];
        result.found = true;
        for (size_t nid : pathNodes) {
            result.nodeNames.push_back(m_roadNodes[nid].name);
        }

        // Stitch road waypoints following exact physical road curvature
        for (size_t i = 0; i + 1 < pathNodes.size(); ++i) {
            size_t u = pathNodes[i];
            size_t v = pathNodes[i + 1];
            for (const auto& edge : m_roadAdjacency[u]) {
                if (edge.toNode == v) {
                    for (const auto& pt : edge.pathGeometry) {
                        if (result.waypoints.empty() || result.waypoints.back() != pt) {
                            result.waypoints.push_back(pt);
                        }
                    }
                    break;
                }
            }
        }

        return result;
    }

    virtual void selectDestinationIndex(size_t index) {
        if (index < m_destinations.size()) {
            m_activeDestinationIndex = index;
            m_routeProgress = 0.0f;
            updateActiveRouteFromDijkstra();
            updateVehiclePositionAlongRoute();
            notifyObservers();
        }
    }

    virtual void startNavigation() {
        m_isNavigating = true;
        notifyObservers();
    }

    virtual void stopNavigation() {
        m_isNavigating = false;
        notifyObservers();
    }

    virtual void toggleNavigation() {
        m_isNavigating = !m_isNavigating;
        notifyObservers();
    }

    virtual void setRouteProgress(float progress) {
        m_routeProgress = std::clamp(progress, 0.0f, 1.0f);
        updateVehiclePositionAlongRoute();
        notifyObservers();
    }

    virtual void registerObserver(NavigationChangedCallback callback) {
        m_observers.push_back(std::move(callback));
    }

private:
    void addBidirectionalEdge(size_t u, size_t v, double distKm, const std::vector<std::pair<double, double>>& points) {
        if (u >= m_roadAdjacency.size() || v >= m_roadAdjacency.size()) return;
        
        RoadEdge edgeForward{v, distKm, points};
        m_roadAdjacency[u].push_back(edgeForward);

        std::vector<std::pair<double, double>> revPoints = points;
        std::reverse(revPoints.begin(), revPoints.end());
        RoadEdge edgeBackward{u, distKm, revPoints};
        m_roadAdjacency[v].push_back(edgeBackward);
    }

    void initRoadNetwork() {
        // 16 key physical road intersections/landmarks across Mysuru
        m_roadNodes = {
            {0,  "GSSSIETW Campus Gate (KRS Road)",               12.354927, 76.618170},
            {1,  "Metagalli Industrial Ring Junction",            12.351858, 76.625498},
            {2,  "Vontikoppal Temple Circle",                     12.341588, 76.631064},
            {3,  "Yadavagiri Railway Crossing Hub",               12.332300, 76.632755},
            {4,  "Mysuru City Railway Station Circle",            12.323334, 76.641891},
            {5,  "Sayyaji Rao Road / K.R. Circle",                12.317108, 76.650115},
            {6,  "Hardinge Circle (Palace North)",                12.309490, 76.652915},
            {7,  "Balarama Gate (Palace North Gate)",             12.307426, 76.652852},
            {8,  "Mysuru Palace Grand Entrance",                  12.303245, 76.655761},
            {9,  "Outer Ring Road Junction (North-West)",         12.357899, 76.603096},
            {10, "Hebbal Cyber Park / Infosys Campus",            12.360688, 76.592966},
            {11, "J.L.B. Road Arterial Bypass",                   12.3200, 76.6350},
            {12, "Ramaswamy Circle (Double Road)",                12.3010, 76.6420},
            {13, "Ballal Circle (Krishnamurthypuram)",            12.2950, 76.6380},
            {14, "Kuvempunagar Hospital Circle",                  12.2982, 76.6265},
            {15, "250 kW EV Supercharger Station Hub",            12.316797, 76.650763}
        };

        m_roadAdjacency.resize(m_roadNodes.size());

        // Road Segments with realistic curvature along actual road tracks
        // Edge 0 - 1: KRS Road (GSSSIETW to Metagalli) (20 road coordinates)
        addBidirectionalEdge(0, 1, 0.9, {
            {12.354927, 76.618170}, {12.354485, 76.618357}, {12.354328, 76.618480}, {12.354266, 76.618528},
            {12.354299, 76.619640}, {12.354368, 76.620620}, {12.354459, 76.622079}, {12.354495, 76.622645},
            {12.354539, 76.623056}, {12.354550, 76.623342}, {12.354562, 76.623474}, {12.354543, 76.623670},
            {12.354374, 76.623929}, {12.353405, 76.624519}, {12.353012, 76.624796}, {12.352461, 76.625137},
            {12.352206, 76.625292}, {12.352037, 76.625395}, {12.351979, 76.625428}, {12.351858, 76.625498}
        });

        // Edge 1 - 2: KRS Road (Metagalli to Vontikoppal) (43 road coordinates)
        addBidirectionalEdge(1, 2, 1.0, {
            {12.351858, 76.625498}, {12.351738, 76.625605}, {12.351610, 76.625750}, {12.351508, 76.626026},
            {12.351465, 76.626465}, {12.351459, 76.626765}, {12.351453, 76.627020}, {12.351520, 76.627240},
            {12.351822, 76.627912}, {12.351936, 76.628230}, {12.351972, 76.628331}, {12.352112, 76.628703},
            {12.352161, 76.628865}, {12.352189, 76.628955}, {12.352206, 76.629013}, {12.352101, 76.629043},
            {12.351692, 76.629118}, {12.351522, 76.629150}, {12.351463, 76.629161}, {12.351335, 76.629188},
            {12.351201, 76.629216}, {12.350831, 76.629293}, {12.350204, 76.629417}, {12.349497, 76.629564},
            {12.349212, 76.629617}, {12.348997, 76.629657}, {12.348147, 76.629806}, {12.347773, 76.629885},
            {12.347559, 76.629931}, {12.347027, 76.630022}, {12.346523, 76.630109}, {12.345648, 76.630277},
            {12.345383, 76.630327}, {12.344980, 76.630413}, {12.344876, 76.630431}, {12.344113, 76.630569},
            {12.343595, 76.630663}, {12.343549, 76.630671}, {12.343543, 76.630672}, {12.343278, 76.630716},
            {12.342709, 76.630840}, {12.342287, 76.630922}, {12.341588, 76.631064}
        });

        // Edge 2 - 3: Kalidasa Road / Temple (Vontikoppal to Yadavagiri) (22 road coordinates)
        addBidirectionalEdge(2, 3, 1.2, {
            {12.341588, 76.631064}, {12.341505, 76.631081}, {12.340597, 76.631275}, {12.339816, 76.631430},
            {12.339218, 76.631556}, {12.339148, 76.631570}, {12.338667, 76.631668}, {12.337845, 76.631838},
            {12.337449, 76.631940}, {12.337127, 76.632023}, {12.336142, 76.632222}, {12.335851, 76.632288},
            {12.335794, 76.632301}, {12.335778, 76.632305}, {12.335296, 76.632396}, {12.335086, 76.632417},
            {12.334968, 76.632429}, {12.334552, 76.632468}, {12.334159, 76.632522}, {12.333525, 76.632595},
            {12.332930, 76.632683}, {12.332300, 76.632755}
        });

        // Edge 3 - 4: Railway Link Road (Yadavagiri to Railway Station Circle) (41 road coordinates)
        addBidirectionalEdge(3, 4, 1.2, {
            {12.332300, 76.632755}, {12.331988, 76.632795}, {12.331921, 76.632804}, {12.331185, 76.632906},
            {12.330206, 76.633034}, {12.329807, 76.633074}, {12.329342, 76.633131}, {12.328672, 76.633218},
            {12.328002, 76.633289}, {12.327320, 76.633381}, {12.327251, 76.633388}, {12.326848, 76.633431},
            {12.326494, 76.633474}, {12.326304, 76.633487}, {12.326229, 76.633501}, {12.326053, 76.633526},
            {12.325720, 76.633657}, {12.325334, 76.633957}, {12.325270, 76.633972}, {12.325132, 76.634097},
            {12.324833, 76.634396}, {12.323626, 76.635604}, {12.322485, 76.636735}, {12.322496, 76.636745},
            {12.322506, 76.636766}, {12.322509, 76.636788}, {12.322504, 76.636810}, {12.322493, 76.636830},
            {12.322476, 76.636844}, {12.322455, 76.636853}, {12.322440, 76.636853}, {12.322725, 76.638393},
            {12.322830, 76.638962}, {12.322862, 76.639576}, {12.322938, 76.640045}, {12.322969, 76.640231},
            {12.323141, 76.641043}, {12.323228, 76.641452}, {12.323322, 76.641747}, {12.323336, 76.641827},
            {12.323334, 76.641891}
        });

        // Edge 4 - 5: Sayyaji Rao Road (Railway Station to K.R. Circle) (31 road coordinates)
        addBidirectionalEdge(4, 5, 1.1, {
            {12.323334, 76.641891}, {12.323292, 76.641970}, {12.323224, 76.642044}, {12.323108, 76.642273},
            {12.323038, 76.642456}, {12.323022, 76.642562}, {12.323049, 76.642666}, {12.323307, 76.643276},
            {12.323384, 76.643464}, {12.323436, 76.643673}, {12.323654, 76.644305}, {12.323819, 76.644779},
            {12.323884, 76.644969}, {12.323987, 76.645265}, {12.322628, 76.645824}, {12.322523, 76.645920},
            {12.321740, 76.646445}, {12.321440, 76.646657}, {12.321010, 76.646960}, {12.320869, 76.647078},
            {12.320741, 76.647179}, {12.320000, 76.647765}, {12.319314, 76.648356}, {12.319182, 76.648479},
            {12.318999, 76.648618}, {12.318923, 76.648675}, {12.318571, 76.648941}, {12.318430, 76.649046},
            {12.317757, 76.649621}, {12.317657, 76.649681}, {12.317108, 76.650115}
        });

        // Edge 5 - 6: Sayyaji Rao Road (K.R. Circle to Hardinge Circle) (19 road coordinates)
        addBidirectionalEdge(5, 6, 0.9, {
            {12.317108, 76.650115}, {12.316352, 76.650572}, {12.315642, 76.650953}, {12.314606, 76.651353},
            {12.314599, 76.651395}, {12.314580, 76.651433}, {12.314553, 76.651464}, {12.314518, 76.651487},
            {12.314478, 76.651499}, {12.314402, 76.651491}, {12.314371, 76.651474}, {12.314344, 76.651451},
            {12.312804, 76.651894}, {12.312117, 76.652105}, {12.311868, 76.652198}, {12.311327, 76.652365},
            {12.310831, 76.652513}, {12.309948, 76.652811}, {12.309490, 76.652915}
        });

        // Edge 6 - 7: Palace North Approach (Hardinge Circle to Balarama Gate) (18 road coordinates)
        addBidirectionalEdge(6, 7, 0.4, {
            {12.309490, 76.652915}, {12.309328, 76.652966}, {12.308986, 76.653059}, {12.308985, 76.653127},
            {12.308964, 76.653191}, {12.308925, 76.653247}, {12.308872, 76.653288}, {12.308810, 76.653311},
            {12.308744, 76.653315}, {12.308676, 76.653296}, {12.308626, 76.653265}, {12.308586, 76.653221},
            {12.308558, 76.653167}, {12.308193, 76.653070}, {12.307853, 76.652978}, {12.307765, 76.652954},
            {12.307646, 76.652916}, {12.307426, 76.652852}
        });

        // Edge 7 - 8: Palace Gate to Grand Entrance (28 road coordinates)
        addBidirectionalEdge(7, 8, 0.2, {
            {12.307426, 76.652852}, {12.306391, 76.652561}, {12.305919, 76.652455}, {12.305546, 76.652372},
            {12.305090, 76.652306}, {12.305065, 76.652302}, {12.304810, 76.652289}, {12.304574, 76.652299},
            {12.304345, 76.652357}, {12.304157, 76.652420}, {12.303757, 76.652635}, {12.303421, 76.652834},
            {12.303340, 76.652866}, {12.303110, 76.652957}, {12.302850, 76.653033}, {12.302837, 76.653044},
            {12.302821, 76.653051}, {12.302804, 76.653054}, {12.302729, 76.655063}, {12.302727, 76.655104},
            {12.302723, 76.655251}, {12.302697, 76.655727}, {12.302776, 76.655733}, {12.302855, 76.655738},
            {12.302978, 76.655745}, {12.303124, 76.655754}, {12.303245, 76.655761}, {12.303245, 76.655761}
        });

        // Edge 0 - 9: KRS Road to Outer Ring Road Junction (36 road coordinates)
        addBidirectionalEdge(0, 9, 1.3, {
            {12.354927, 76.618170}, {12.354485, 76.618357}, {12.354328, 76.618480}, {12.354257, 76.616577},
            {12.354201, 76.615469}, {12.354166, 76.614564}, {12.354122, 76.614109}, {12.354077, 76.613900},
            {12.354017, 76.613631}, {12.353941, 76.613307}, {12.353891, 76.613098}, {12.353808, 76.612760},
            {12.353792, 76.612695}, {12.353776, 76.612554}, {12.353762, 76.612425}, {12.353756, 76.611277},
            {12.353737, 76.610830}, {12.353730, 76.610170}, {12.353738, 76.609175}, {12.353753, 76.608571},
            {12.353725, 76.607940}, {12.353701, 76.607576}, {12.353653, 76.607362}, {12.353636, 76.607298},
            {12.353599, 76.607166}, {12.353529, 76.607090}, {12.354050, 76.606475}, {12.355275, 76.605092},
            {12.355359, 76.605077}, {12.355710, 76.604646}, {12.356076, 76.604258}, {12.356158, 76.604172},
            {12.356780, 76.603665}, {12.357300, 76.603401}, {12.357718, 76.603188}, {12.357899, 76.603096}
        });

        // Edge 9 - 10: Outer Ring Road to Infosys / Hebbal Cyber Park (38 road coordinates)
        addBidirectionalEdge(9, 10, 1.6, {
            {12.357899, 76.603096}, {12.357885, 76.602664}, {12.357850, 76.601689}, {12.357810, 76.600362},
            {12.357799, 76.600162}, {12.357793, 76.600053}, {12.357784, 76.599872}, {12.357776, 76.599710},
            {12.357698, 76.597827}, {12.357576, 76.595116}, {12.357572, 76.595029}, {12.357566, 76.594956},
            {12.357795, 76.594957}, {12.358062, 76.594945}, {12.358186, 76.594940}, {12.358232, 76.594938},
            {12.358711, 76.594918}, {12.358968, 76.594905}, {12.359493, 76.594882}, {12.359873, 76.594866},
            {12.359935, 76.594850}, {12.359980, 76.594814}, {12.360005, 76.594749}, {12.360010, 76.594652},
            {12.359892, 76.593442}, {12.359918, 76.593375}, {12.359912, 76.593306}, {12.359917, 76.593260},
            {12.359931, 76.593211}, {12.359965, 76.593176}, {12.360010, 76.593142}, {12.360070, 76.593107},
            {12.360167, 76.593058}, {12.360245, 76.593034}, {12.360348, 76.593010}, {12.360442, 76.592999},
            {12.360688, 76.592966}, {12.360688, 76.592966}
        });

        // Edge 5 - 15: Sayyaji Rao Road to 250 kW EV Supercharger Station (5 road coordinates)
        addBidirectionalEdge(5, 15, 0.15, {
            {12.317657, 76.649681}, {12.317108, 76.650115}, {12.317096, 76.650320}, {12.317007, 76.650745},
            {12.316797, 76.650763}
        });

        // Edge 6 - 15: Hardinge Circle to Supercharger Station (3 road coordinates)
        addBidirectionalEdge(6, 15, 0.9, {
            {12.309490, 76.652915}, {12.313000, 76.651500}, {12.316797, 76.650763}
        });

    }

    void initDestinations() {
        m_destinations = {
            {
                "palace",
                "Mysuru Palace",
                "Landmark",
                "🏰",
                8.4f,
                18,
                "In 450 m, turn right onto Palace Road",
                "↱",
                0.74f,
                0.26f,
                12.3052,
                76.6552,
                12.3551,
                76.6186,
                "Sayyaji Rao Rd, Agrahara, Chamrajpura, Mysuru, KA 570001",
                60,
                82,
                {},
                0, // startNode: GSSSIETW Campus Gate
                8  // targetNode: Mysuru Palace Entrance
            },
            {
                "home",
                "Home (North District)",
                "Favorite",
                "🏠",
                4.2f,
                9,
                "In 300 m, turn left onto KRS Road",
                "↰",
                0.28f,
                0.35f,
                12.3551,
                76.6186,
                12.3325,
                76.6342,
                "KRS Rd, North District, Metagalli, Mysuru, KA 570016",
                50,
                89,
                {},
                2, // startNode: Vontikoppal
                0  // targetNode: GSSSIETW / North Home
            },
            {
                "supercharger",
                "Tesla / Ather 250 kW Supercharger",
                "Charging",
                "⚡",
                2.1f,
                5,
                "In 150 m, destination on your right",
                "↗",
                0.55f,
                0.45f,
                12.3168,
                76.6508,
                12.3052,
                76.6552,
                "Sayyaji Rao Rd Central Charging Hub, Mysuru",
                50,
                84,
                {},
                0,
                15 // targetNode: Supercharger Station
            },
            {
                "campus",
                "Technology University Campus",
                "Education",
                "🏫",
                13.8f,
                24,
                "In 2.1 km, sharp right on Hill Road",
                "↻",
                0.65f,
                0.82f,
                12.2748,
                76.6705,
                12.3052,
                76.6552,
                "GSSSIETW / VTU Technology Campus, Mysuru 570010",
                40,
                73,
                {},
                0,
                13 // targetNode: Ballal Circle / Campus
            },
            {
                "cyberpark",
                "Cyber Park (Infosys Campus Hebbal)",
                "Work",
                "🏢",
                11.2f,
                16,
                "In 800 m, merge onto Outer Ring Road",
                "↖",
                0.80f,
                0.68f,
                12.3615,
                76.5938,
                12.3551,
                76.6186,
                "Hebbal Industrial Area, Mysuru, Karnataka 570027",
                80,
                79,
                {},
                0,
                10 // targetNode: Cyber Park
            },
            {
                "brindavan",
                "KRS Dam & Brindavan Nature Reserve",
                "Landmark",
                "🌊",
                19.5f,
                28,
                "In 3.4 km, continue straight on State Highway 22",
                "↑",
                0.35f,
                0.15f,
                12.4244,
                76.5728,
                12.3551,
                76.6186,
                "Krishnaraja Sagar, Mandya/Mysuru, Karnataka",
                70,
                71,
                {},
                0,
                9
            },
            {
                "hospital",
                "Apollo BGS Multi-Specialty Hospital",
                "Emergency",
                "🏥",
                6.8f,
                12,
                "In 600 m, turn right onto Kuvempunagar Main Rd",
                "↱",
                0.40f,
                0.70f,
                12.2982,
                76.6265,
                12.3551,
                76.6186,
                "Adichunchanagiri Road, Kuvempunagar, Mysuru 570023",
                60,
                85,
                {},
                0,
                14 // targetNode: Kuvempunagar Hospital Circle
            },
            {
                "airport",
                "Kempegowda Int'l Airport (Bengaluru)",
                "Landmark",
                "✈️",
                168.0f,
                135,
                "Merge onto Bengaluru-Mysuru 10-Lane Expressway",
                "↑",
                0.90f,
                0.10f,
                13.1986,
                77.7066,
                12.3551,
                76.6186,
                "KIAL Rd, Devanahalli, Bengaluru, Karnataka 560300",
                100,
                42,
                {},
                0,
                4
            }
        };

        m_activeDestinationIndex = 0;
        updateActiveRouteFromDijkstra();
        updateVehiclePositionAlongRoute();
    }

    void updateActiveRouteFromDijkstra() {
        if (m_activeDestinationIndex >= m_destinations.size()) return;

        auto& dest = m_destinations[m_activeDestinationIndex];
        m_activeShortestPath = computeDijkstraShortestPath(dest.startNodeId, dest.targetNodeId);

        if (m_activeShortestPath.found && !m_activeShortestPath.waypoints.empty()) {
            dest.waypoints = m_activeShortestPath.waypoints;
            m_activeShortestPath.totalDistanceKm = dest.distanceKm;
        }
    }

    void updateVehiclePositionAlongRoute() {
        const auto& active = m_destinations[m_activeDestinationIndex];
        const auto& wps = active.waypoints;
        if (wps.empty()) {
            m_currentLat = active.startLat;
            m_currentLon = active.startLon;
            m_currentHeading = 0.0;
            m_vehicleSpeed = 0.0;
            return;
        }

        if (wps.size() == 1 || m_routeProgress <= 0.0f) {
            m_currentLat = wps.front().first;
            m_currentLon = wps.front().second;
            m_currentHeading = 42.0;
            m_vehicleSpeed = 0.0;
            return;
        }

        if (m_routeProgress >= 1.0f) {
            m_currentLat = wps.back().first;
            m_currentLon = wps.back().second;
            m_vehicleSpeed = 0.0;
            return;
        }

        // Segment interpolation along shortest path road waypoints
        const float totalSegments = static_cast<float>(wps.size() - 1);
        const float segFloat = m_routeProgress * totalSegments;
        const size_t segIdx = static_cast<size_t>(segFloat);
        const float frac = segFloat - static_cast<float>(segIdx);

        if (segIdx + 1 < wps.size()) {
            const auto& p1 = wps[segIdx];
            const auto& p2 = wps[segIdx + 1];
            m_currentLat = p1.first + (p2.first - p1.first) * frac;
            m_currentLon = p1.second + (p2.second - p1.second) * frac;

            // Compute forward vehicle bearing heading (degrees from North)
            const double dLon = (p2.second - p1.second) * (3.141592653589793 / 180.0);
            const double lat1 = p1.first * (3.141592653589793 / 180.0);
            const double lat2 = p2.first * (3.141592653589793 / 180.0);
            const double y = std::sin(dLon) * std::cos(lat2);
            const double x = std::cos(lat1) * std::sin(lat2) - std::sin(lat1) * std::cos(lat2) * std::cos(dLon);
            double brng = std::atan2(y, x) * (180.0 / 3.141592653589793);
            if (brng < 0.0) brng += 360.0;
            m_currentHeading = brng;

            // Realistic cruising vehicle speed based on road category (e.g. 52 km/h)
            m_vehicleSpeed = std::max(25.0, static_cast<double>(active.speedLimitKmH) - 6.0 + 3.0 * std::sin(m_routeProgress * 12.0));
        }
    }

    void notifyObservers() {
        for (const auto& obs : m_observers) {
            if (obs) obs();
        }
    }

    SafetyPolicy* m_safetyPolicy{nullptr};
    std::vector<RoadNode> m_roadNodes;
    std::vector<std::vector<RoadEdge>> m_roadAdjacency;
    DijkstraResult m_activeShortestPath;

    std::vector<NavigationDestination> m_destinations;
    size_t m_activeDestinationIndex{0};
    bool m_isNavigating{true};
    float m_routeProgress{0.25f};

    // Moving Vehicle Telemetry
    double m_currentLat{12.3410};
    double m_currentLon{76.6268};
    double m_currentHeading{45.0};
    double m_vehicleSpeed{52.0};

    // User's Current Location (Distinct Pin on the Map)
    double m_userLat{12.3551};
    double m_userLon{76.6186};
    std::string m_userLocationTitle{"Current Location of the User"};
    std::string m_userLocationAddress{"GSSSIETW Campus, KRS Road, Mysuru"};

    std::vector<NavigationChangedCallback> m_observers;
};

} // namespace driveos::domain
