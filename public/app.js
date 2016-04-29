(function () {
	angular.module('StatusDashboard', [
		'ngMessages',
		'ngWebSocket',
		'chart.js'
	]).controller('RootCtrl', [
		'$scope',
		'$http',
		function ($scope, $http) {
			console.log("Setting up root controller");
		}
	]).service('statusService', [
		'$http',
		'$websocket',
		'websocketUri',
		function ($http, $websocket, websocketUri) {
			var status = {};

			var dataStream = $websocket(websocketUri);
			dataStream.onMessage(function(message) {
				var data = JSON.parse(message.data);
				Object.keys(data).forEach(function (key) {
					status[key] = data[key];
				});
			});

			return {
				getServiceStatus: function (serviceId) {
					return (status && serviceId && serviceId in status)
						? status[serviceId]
						: null;
				}
			};
		}
	]).directive('icingaClassic', [
		'statusService',
		function (statusService) {
			var HOST_STATUSES = ['UP', 'DOWN', 'UNREACHABLE'];
			var SERVICE_STATUSES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN', 'DEPENDENT'];
			return {
				restrict: 'E',
				link:     function (scope, element, attrs) {
					scope.$watch(function () {
						return statusService.getServiceStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						console.log("Old: ", oldValue, "New: ", newValue);

						var hostStats = {};
						var hostStatus = {};
						var serviceStats = {};
						var serviceStatus = {};
						HOST_STATUSES.forEach(function (status) {
							hostStats[status] = 0;
							hostStatus[status] = false;
						});
						newValue.hosts.status.host_status.forEach(function (host) {
							hostStats[host.status]++;
							hostStatus[host.status] = true;
						});
						SERVICE_STATUSES.forEach(function (status) {
							serviceStats[status] = 0;
							serviceStatus[status] = false;
						});
						newValue.services.status.service_status.forEach(function (service) {
							serviceStats[service.status]++;
							serviceStatus[service.status] = true;
						});
						scope.hostStats = hostStats;
						scope.hostStatus = hostStatus;
						scope.serviceStats = serviceStats;
						scope.serviceStatus = serviceStatus;
					});
				},
				replace: false,
				templateUrl: 'templates/icinga-classic.html',
				scope: {
					statusId: '@statusId'
				}
			}
		}
	]).directive('redmineIssues', [
		'statusService',
		function (statusService) {
			return {
				restrict: 'E',
				link:     function (scope, element, attrs) {
					scope.chartLabels  = [];
					scope.chartSeries  = [];
					scope.chartData    = [[]];
					scope.statusStats  = [];
					scope.chartOptions = {
						scales: {
							xAxes: [{
								stacked: true
							}],
							yAxes: [{
								stacked: true
							}]
						}
					};

					scope.$watch(function () {
						return statusService.getServiceStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						console.log("Old: ", oldValue, "New: ", newValue);

						var statusStats = {};
						var trackers = {};
						newValue.issues.forEach(function (issue) {
							if (!statusStats[issue.status.id]) {
								statusStats[issue.status.id] = {
									id: issue.status.id,
									name: issue.status.name,
									count: 0,
									tracker: {}
								};
								scope.statusStats.push(statusStats[issue.status.id]);
							}
							if (!statusStats[issue.status.id].tracker[issue.tracker.id]) {
								statusStats[issue.status.id].tracker[issue.tracker.id] = {
									id: issue.tracker.id,
									name: issue.tracker.name,
									count: 0
								}
							}
							statusStats[issue.status.id].count++;
							statusStats[issue.status.id].tracker[issue.tracker.id].count++;
							if (!trackers[issue.tracker.id]) {
								trackers[issue.tracker.id] = {
									name: issue.tracker.name,
									id: issue.tracker.id
								};
							}
						});
						var trackerList = [];
						Object.keys(trackers).forEach(function (trackerId) {
							trackerList.push(trackers[trackerId]);
						});
						trackerList.sort(function (a, b) {
							return a.name.localeCompare(b.name);
						});
						scope.chartSeries = trackerList.map(function (tracker) {
							return tracker.name;
						});
						scope.chartLabels.length = 0;
						scope.chartData[0].length = 0;
						scope.statusStats.forEach(function (statusType) {
							scope.chartLabels.push(statusType.name);
							trackerList.forEach(function (tracker, index) {
								if (!scope.chartData[index]) {
									scope.chartData[index] = [];
								}
								scope.chartData[index].push(
									statusType.tracker[tracker.id]
										? statusType.tracker[tracker.id].count
										: 0
								);
							})
						});
						scope.issueCount = newValue.issues.length;
					});
				},
				replace: false,
				templateUrl: 'templates/redmine-issues.html',
				scope: {
					statusId: '@statusId'
				}
			}
		}
	]);
})();
